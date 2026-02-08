# 10 - Coordinación de Transportes y Enrutamiento Inteligente

## Descripción

Este ejemplo demuestra cómo coordinar múltiples transportes de comunicación (BLE, WiFi, Cellular, Nostr) para lograr conectividad óptima y failover automático. Aprenderás a implementar un sistema de enrutamiento inteligente que selecciona automáticamente el mejor transporte disponible, maneja transiciones suaves entre redes, y mantiene la consistencia de mensajes a través de diferentes canales.

**Beneficios:**
- Conectividad máxima aprovechando todos los transportes disponibles
- Failover automático cuando un transporte falla
- Optimización de rendimiento basada en condiciones de red
- Consistencia de mensajes a través de múltiples transportes
- Adaptación automática a cambios en el entorno de red
- Balanceo de carga inteligente entre transportes

**Consideraciones:**
- Requiere gestión cuidadosa del estado de conexión
- Implementa timeouts apropiados para cada transporte
- Considera el consumo de batería de mantener múltiples conexiones
- Maneja conflictos de mensajes duplicados
- Implementa compresión para transportes de alta latencia
- Considera políticas de privacidad por transporte

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Implementar Transportes Individuales** (BLE, WiFi, Cellular)
3. **Crear TransportCoordinator** y **RoutingEngine**
4. **Configurar políticas de enrutamiento**
5. **Implementar MessageDeduplication**

## Código de Implementación

```swift
import BitchatCore
import BitchatBLE
import BitchatNostr
import Network
import Combine

// Coordinador principal de transportes
class TransportCoordinator {
    private let bleTransport: BLETransport
    private let wifiTransport: WiFiTransport
    private let cellularTransport: CellularTransport
    private let nostrTransport: NostrTransport

    private let routingEngine: RoutingEngine
    private let messageDeduplicator: MessageDeduplicator
    private let connectionMonitor: ConnectionMonitor

    // Estado de transportes
    private var activeTransports: Set<TransportType> = []
    private var transportStates: [TransportType: TransportState] = [:]
    private var messageQueue: MessageQueue

    // Publishers para eventos
    private let transportStatusPublisher = PassthroughSubject<TransportStatus, Never>()
    private let messageReceivedPublisher = PassthroughSubject<(Message, TransportType), Never>()

    var transportStatus: AnyPublisher<TransportStatus, Never> {
        transportStatusPublisher.eraseToAnyPublisher()
    }

    var messageReceived: AnyPublisher<(Message, TransportType), Never> {
        messageReceivedPublisher.eraseToAnyPublisher()
    }

    init() {
        self.bleTransport = BLETransport()
        self.wifiTransport = WiFiTransport()
        self.cellularTransport = CellularTransport()
        self.nostrTransport = NostrTransport()

        self.routingEngine = RoutingEngine()
        self.messageDeduplicator = MessageDeduplicator()
        self.connectionMonitor = ConnectionMonitor()
        self.messageQueue = MessageQueue()

        setupTransportDelegation()
        setupConnectionMonitoring()
    }

    // MARK: - Inicialización y Configuración

    // Iniciar todos los transportes disponibles
    func startAllTransports() async throws {
        print("🚀 Iniciando coordinación de transportes...")

        // Iniciar BLE (siempre disponible)
        try await startTransport(.ble)

        if await isWiFiAvailable() {
            do {
                try await startTransport(.wifi)
            } catch {
                print("Error iniciando WiFi: \(error.localizedDescription)")
            }
        }

        // Verificar e iniciar Cellular
        if await isCellularAvailable() {
            do {
                try await startTransport(.cellular)
            } catch {
                print("Error iniciando Cellular: \(error.localizedDescription)")
            }
        }

        // Iniciar Nostr (siempre disponible)
        try await startTransport(.nostr)

        // Iniciar monitoreo de conexiones
        await connectionMonitor.startMonitoring()

        print("✅ Coordinación de transportes iniciada")
    }

    // Detener todos los transportes
    func stopAllTransports() async {
        print("🛑 Deteniendo coordinación de transportes...")

        for transport in activeTransports {
            await stopTransport(transport)
        }

        await connectionMonitor.stopMonitoring()

        print("✅ Coordinación de transportes detenida")
    }

    // MARK: - Gestión de Transportes

    // Iniciar transporte específico
    private func startTransport(_ type: TransportType) async throws {
        guard !activeTransports.contains(type) else { return }

        let transport = getTransport(for: type)

        do {
            try await transport.start()
            activeTransports.insert(type)
            transportStates[type] = .connected

            transportStatusPublisher.send(.transportConnected(type))

            print("📡 Transporte \(type) iniciado")
        } catch {
            transportStates[type] = .failed(error)
            transportStatusPublisher.send(.transportFailed(type, error))
            throw error
        }
    }

    // Detener transporte específico
    private func stopTransport(_ type: TransportType) async {
        guard activeTransports.contains(type) else { return }

        let transport = getTransport(for: type)
        await transport.stop()

        activeTransports.remove(type)
        transportStates[type] = .disconnected

        transportStatusPublisher.send(.transportDisconnected(type))

        print("📡 Transporte \(type) detenido")
    }

    // MARK: - Enrutamiento Inteligente

    // Enviar mensaje con enrutamiento óptimo
    func sendMessage(_ message: Message, priority: MessagePriority = .normal) async throws {
        let routingDecision = await routingEngine.decideRoute(for: message, priority: priority)

        // Intentar rutas en orden de preferencia
        for route in routingDecision.routes {
            do {
                try await sendViaTransport(message, transport: route.transport, options: route.options)
                print("📤 Mensaje enviado vía \(route.transport) (prioridad: \(priority))")
                return
            } catch {
                print("❌ Falló envío vía \(route.transport): \(error.localizedDescription)")
                // Continuar con siguiente ruta
            }
        }

        // Si todas las rutas fallan, encolar para reintento
        await messageQueue.enqueue(message, priority: priority)
        throw TransportError.allRoutesFailed
    }

    // Enviar mensaje a través de transporte específico
    private func sendViaTransport(_ message: Message, transport: TransportType, options: RoutingOptions) async throws {
        let transportInstance = getTransport(for: transport)

        // Aplicar opciones de enrutamiento
        var processedMessage = message

        if options.compress {
            processedMessage = try await compressMessage(message)
        }

        if options.encrypt {
            processedMessage = try await encryptMessage(processedMessage)
        }

        if options.split {
            let chunks = try splitMessage(processedMessage, chunkSize: options.chunkSize)
            for chunk in chunks {
                try await transportInstance.send(chunk)
            }
        } else {
            try await transportInstance.send(processedMessage)
        }
    }

    // MARK: - Recepción y Procesamiento

    // Procesar mensaje recibido
    private func processReceivedMessage(_ message: Message, from transport: TransportType) async {
        // Verificar duplicados
        guard await messageDeduplicator.isUnique(message) else {
            print("🔄 Mensaje duplicado ignorado")
            return
        }

        // Marcar como procesado
        await messageDeduplicator.markProcessed(message)

        // Notificar recepción
        messageReceivedPublisher.send((message, transport))

        print("📥 Mensaje recibido vía \(transport)")
    }

    // MARK: - Monitoreo y Failover

    // Manejar cambio en estado de transporte
    private func handleTransportStateChange(_ type: TransportType, state: TransportState) async {
        transportStates[type] = state

        switch state {
        case .connected:
            // Transporte recuperado - reenviar mensajes encolados
            await retryQueuedMessages(for: type)

        case .disconnected:
            // Transporte perdido - intentar failover
            await handleTransportFailure(type)

        case .failed(let error):
            // Transporte falló - log y intentar recuperación
            print("❌ Transporte \(type) falló: \(error.localizedDescription)")
            await attemptTransportRecovery(type)
        }
    }

    // Manejar fallo de transporte
    private func handleTransportFailure(_ type: TransportType) async {
        print("🔄 Iniciando failover para transporte \(type)")

        // Encontrar transportes alternativos disponibles
        let availableTransports = activeTransports.filter { $0 != type }

        if availableTransports.isEmpty {
            print("⚠️ No hay transportes alternativos disponibles")
            return
        }

        // Reenviar mensajes críticos a través de alternativas
        await failoverCriticalMessages(from: type, to: availableTransports)
    }

    // Intentar recuperación de transporte
    private func attemptTransportRecovery(_ type: TransportType) async {
        do {
            try await Task.sleep(nanoseconds: 5_000_000_000) // Esperar 5 segundos
            try await startTransport(type)
            print("✅ Transporte \(type) recuperado")
        } catch {
            print("❌ Recuperación de transporte \(type) falló: \(error.localizedDescription)")
            // Programar reintento posterior
        }
    }

    // MARK: - Utilidades de Mensajes

    // Comprimir mensaje
    private func compressMessage(_ message: Message) async throws -> Message {
        let compressedData = try await Compression.compress(message.data)
        return Message(id: message.id, data: compressedData, metadata: message.metadata)
    }

    // Encriptar mensaje
    private func encryptMessage(_ message: Message) async throws -> Message {
        // Implementar encriptación
        return message // Placeholder
    }

    // Dividir mensaje en chunks
    private func splitMessage(_ message: Message, chunkSize: Int) throws -> [Message] {
        let data = message.data
        var chunks: [Message] = []
        var offset = 0

        while offset < data.count {
            let chunkLength = min(chunkSize, data.count - offset)
            let chunkData = data[offset..<offset + chunkLength]

            let chunk = Message(
                id: message.id,
                data: Data(chunkData),
                metadata: message.metadata.merging([
                    "chunk": "\(chunks.count)",
                    "totalChunks": "unknown" // Se actualizará después
                ]) { _, new in new }
            )

            chunks.append(chunk)
            offset += chunkLength
        }

        // Actualizar metadatos con total de chunks
        for i in 0..<chunks.count {
            chunks[i].metadata["totalChunks"] = "\(chunks.count)"
        }

        return chunks
    }

    // MARK: - Gestión de Cola

    // Reintentar mensajes encolados
    private func retryQueuedMessages(for transport: TransportType) async {
        let messages = await messageQueue.dequeue(for: transport)

        for message in messages {
            do {
                try await sendMessage(message)
                print("📤 Mensaje reenviado exitosamente")
            } catch {
                print("❌ Reenvío falló, reencolando: \(error.localizedDescription)")
                await messageQueue.reenqueue(message)
            }
        }
    }

    // Failover de mensajes críticos
    private func failoverCriticalMessages(from failedTransport: TransportType, to availableTransports: Set<TransportType>) async {
        let criticalMessages = await messageQueue.getCriticalMessages()

        for message in criticalMessages {
            for transport in availableTransports {
                do {
                    try await sendViaTransport(message, transport: transport, options: .reliable)
                    await messageQueue.remove(message)
                    print("🔄 Mensaje crítico failovereado a \(transport)")
                    break
                } catch {
                    continue // Intentar siguiente transporte
                }
            }
        }
    }

    // MARK: - Utilidades

    private func getTransport(for type: TransportType) -> Transport {
        switch type {
        case .ble: return bleTransport
        case .wifi: return wifiTransport
        case .cellular: return cellularTransport
        case .nostr: return nostrTransport
        }
    }

    private func isWiFiAvailable() async -> Bool {
        // Verificar conectividad WiFi
        return true // Placeholder
    }

    private func isCellularAvailable() async -> Bool {
        // Verificar conectividad celular
        return true // Placeholder
    }

    private func setupTransportDelegation() {
        // Configurar delegados para todos los transportes
        let transports: [TransportType: Transport] = [
            .ble: bleTransport,
            .wifi: wifiTransport,
            .cellular: cellularTransport,
            .nostr: nostrTransport
        ]

        for (type, transport) in transports {
            transport.onMessageReceived = { [weak self] message in
                Task { await self?.processReceivedMessage(message, from: type) }
            }

            transport.onStateChanged = { [weak self] state in
                Task { await self?.handleTransportStateChange(type, state: state) }
            }
        }
    }

    private func setupConnectionMonitoring() {
        connectionMonitor.onNetworkChange = { [weak self] networkType in
            Task { await self?.handleNetworkChange(networkType) }
        }
    }

    private func handleNetworkChange(_ networkType: NetworkType) async {
        switch networkType {
        case .wifi:
            if !activeTransports.contains(.wifi) {
                try? await startTransport(.wifi)
            }
        case .cellular:
            if !activeTransports.contains(.cellular) {
                try? await startTransport(.cellular)
            }
        case .none:
            // Network lost - rely on BLE and Nostr
            break
        }
    }
}

// Engine de enrutamiento inteligente
class RoutingEngine {
    private var transportMetrics: [TransportType: TransportMetrics] = [:]
    private let routingPolicies: [RoutingPolicy]

    init() {
        self.routingPolicies = [
            BandwidthRoutingPolicy(),
            LatencyRoutingPolicy(),
            ReliabilityRoutingPolicy(),
            BatteryRoutingPolicy()
        ]

        // Inicializar métricas
        for transport in TransportType.allCases {
            transportMetrics[transport] = TransportMetrics()
        }
    }

    // Decidir ruta óptima para un mensaje
    func decideRoute(for message: Message, priority: MessagePriority) async -> RoutingDecision {
        var candidates: [(transport: TransportType, score: Double, options: RoutingOptions)] = []

        // Evaluar cada transporte disponible
        for transport in TransportType.allCases {
            guard let metrics = transportMetrics[transport] else { continue }

            var score = 0.0
            var options = RoutingOptions()

            // Aplicar políticas de enrutamiento
            for policy in routingPolicies {
                let result = policy.evaluate(transport, metrics, message, priority)
                score += result.score
                options = options.merging(result.options)
            }

            candidates.append((transport, score, options))
        }

        // Ordenar por score descendente
        candidates.sort { $0.score > $1.score }

        // Crear decisión de enrutamiento
        let routes = candidates.map { candidate in
            RoutingRoute(transport: candidate.transport, options: candidate.options)
        }

        return RoutingDecision(routes: routes, reason: "Evaluación de políticas completada")
    }

    // Actualizar métricas de transporte
    func updateMetrics(for transport: TransportType, metrics: TransportMetrics) {
        transportMetrics[transport] = metrics
    }
}

// Políticas de enrutamiento
protocol RoutingPolicy {
    func evaluate(_ transport: TransportType, _ metrics: TransportMetrics, _ message: Message, _ priority: MessagePriority) -> RoutingResult
}

struct RoutingResult {
    let score: Double
    let options: RoutingOptions
}

class BandwidthRoutingPolicy: RoutingPolicy {
    func evaluate(_ transport: TransportType, _ metrics: TransportMetrics, _ message: Message, _ priority: MessagePriority) -> RoutingResult {
        let bandwidthScore = Double(metrics.bandwidth) / 1000.0 // Normalizar
        let options = RoutingOptions(compress: message.data.count > 1024) // Comprimir mensajes grandes
        return RoutingResult(score: bandwidthScore, options: options)
    }
}

class LatencyRoutingPolicy: RoutingPolicy {
    func evaluate(_ transport: TransportType, _ metrics: TransportMetrics, _ message: Message, _ priority: MessagePriority) -> RoutingResult {
        let latencyScore = 1.0 / (1.0 + Double(metrics.latency)) // Menor latencia = mayor score
        let options = RoutingOptions()
        return RoutingResult(score: latencyScore * (priority == .high ? 2.0 : 1.0), options: options)
    }
}

class ReliabilityRoutingPolicy: RoutingPolicy {
    func evaluate(_ transport: TransportType, _ metrics: TransportMetrics, _ message: Message, _ priority: MessagePriority) -> RoutingResult {
        let reliabilityScore = metrics.reliability
        let options = RoutingOptions(encrypt: true) // Siempre encriptar para confiabilidad
        return RoutingResult(score: reliabilityScore, options: options)
    }
}

class BatteryRoutingPolicy: RoutingPolicy {
    func evaluate(_ transport: TransportType, _ metrics: TransportMetrics, _ message: Message, _ priority: MessagePriority) -> RoutingResult {
        // Penalizar transportes que consumen mucha batería
        let batteryPenalty = transport == .cellular ? 0.8 : 1.0
        let options = RoutingOptions()
        return RoutingResult(score: batteryPenalty, options: options)
    }
}

// Estructuras de datos
enum TransportType: CaseIterable {
    case ble, wifi, cellular, nostr
}

enum TransportState {
    case disconnected
    case connecting
    case connected
    case failed(Error)
}

enum MessagePriority {
    case low, normal, high, critical
}

enum NetworkType {
    case wifi, cellular, none
}

struct TransportStatus {
    let transport: TransportType
    let state: TransportState
    let timestamp: Date

    static func transportConnected(_ type: TransportType) -> TransportStatus {
        TransportStatus(transport: type, state: .connected, timestamp: Date())
    }

    static func transportDisconnected(_ type: TransportType) -> TransportStatus {
        TransportStatus(transport: type, state: .disconnected, timestamp: Date())
    }

    static func transportFailed(_ type: TransportType, _ error: Error) -> TransportStatus {
        TransportStatus(transport: type, state: .failed(error), timestamp: Date())
    }
}

struct TransportMetrics {
    var bandwidth: Int = 1000 // bytes/second
    var latency: TimeInterval = 0.1 // seconds
    var reliability: Double = 0.95 // 0-1
    var lastUpdate: Date = Date()
}

struct RoutingDecision {
    let routes: [RoutingRoute]
    let reason: String
}

struct RoutingRoute {
    let transport: TransportType
    let options: RoutingOptions
}

struct RoutingOptions {
    var compress: Bool = false
    var encrypt: Bool = false
    var split: Bool = false
    var chunkSize: Int = 1024

    static let reliable = RoutingOptions(compress: true, encrypt: true)
    static let fast = RoutingOptions(compress: false, encrypt: false)
}

struct Message {
    let id: MessageID
    let data: Data
    let metadata: [String: String]

    init(id: MessageID, data: Data, metadata: [String: String] = [:]) {
        self.id = id
        self.data = data
        self.metadata = metadata
    }
}

struct MessageID: Hashable {
    let uuid: UUID

    init() {
        self.uuid = UUID()
    }
}

// Protocolos y clases de transporte
protocol Transport {
    var onMessageReceived: ((Message) -> Void)? { get set }
    var onStateChanged: ((TransportState) -> Void)? { get set }

    func start() async throws
    func stop() async
    func send(_ message: Message) async throws
}

class BLETransport: Transport {
    var onMessageReceived: ((Message) -> Void)?
    var onStateChanged: ((TransportState) -> Void)?

    func start() async throws { /* Implementación BLE */ }
    func stop() async { /* Implementación BLE */ }
    func send(_ message: Message) async throws { /* Implementación BLE */ }
}

class WiFiTransport: Transport {
    var onMessageReceived: ((Message) -> Void)?
    var onStateChanged: ((TransportState) -> Void)?

    func start() async throws { /* Implementación WiFi */ }
    func stop() async { /* Implementación WiFi */ }
    func send(_ message: Message) async throws { /* Implementación WiFi */ }
}

class CellularTransport: Transport {
    var onMessageReceived: ((Message) -> Void)?
    var onStateChanged: ((TransportState) -> Void)?

    func start() async throws { /* Implementación Cellular */ }
    func stop() async { /* Implementación Cellular */ }
    func send(_ message: Message) async throws { /* Implementación Cellular */ }
}

class NostrTransport: Transport {
    var onMessageReceived: ((Message) -> Void)?
    var onStateChanged: ((TransportState) -> Void)?

    func start() async throws { /* Implementación Nostr */ }
    func stop() async { /* Implementación Nostr */ }
    func send(_ message: Message) async throws { /* Implementación Nostr */ }
}

// Utilidades adicionales
class MessageDeduplicator {
    private var processedMessages: Set<MessageID> = []
    private let maxCacheSize = 1000

    func isUnique(_ message: Message) async -> Bool {
        if processedMessages.contains(message.id) {
            return false
        }

        // Limpiar cache si es necesario
        if processedMessages.count >= maxCacheSize {
            processedMessages.removeFirst(processedMessages.count / 2)
        }

        return true
    }

    func markProcessed(_ message: Message) async {
        processedMessages.insert(message.id)
    }
}

class MessageQueue {
    private var queues: [MessagePriority: [Message]] = [
        .low: [],
        .normal: [],
        .high: [],
        .critical: []
    ]

    func enqueue(_ message: Message, priority: MessagePriority) async {
        queues[priority]?.append(message)
    }

    func dequeue(for transport: TransportType) async -> [Message] {
        var messages: [Message] = []

        for priority in [MessagePriority.critical, .high, .normal, .low] {
            if let queue = queues[priority], !queue.isEmpty {
                messages.append(contentsOf: queue)
                queues[priority] = []
            }
        }

        return messages
    }

    func reenqueue(_ message: Message) async {
        // Reencolar con prioridad reducida
        await enqueue(message, priority: .low)
    }

    func getCriticalMessages() async -> [Message] {
        return queues[.critical] ?? []
    }

    func remove(_ message: Message) async {
        for (priority, messages) in queues {
            queues[priority] = messages.filter { $0.id != message.id }
        }
    }
}

class ConnectionMonitor {
    var onNetworkChange: ((NetworkType) -> Void)?

    func startMonitoring() async {
        // Implementar monitoreo de cambios de red
    }

    func stopMonitoring() async {
        // Detener monitoreo
    }
}

// Errores
enum TransportError: Error {
    case allRoutesFailed
    case transportNotAvailable
    case messageTooLarge
}

// Controlador de UI para coordinación de transportes
class TransportViewController: UIViewController {
    private let coordinator: TransportCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: TransportCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        // Crear UI para mostrar estado de transportes
        // Botones para enviar mensajes de prueba
        // Indicadores de estado de cada transporte
    }

    private func setupBindings() {
        // Observar cambios en estado de transportes
        coordinator.transportStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateTransportStatus(status)
            }
            .store(in: &cancellables)

        // Observar mensajes recibidos
        coordinator.messageReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message, transport in
                self?.handleReceivedMessage(message, from: transport)
            }
            .store(in: &cancellables)
    }

    private func updateTransportStatus(_ status: TransportStatus) {
        // Actualizar UI según estado del transporte
        print("Transporte \(status.transport) cambió a estado: \(status.state)")
    }

    private func handleReceivedMessage(_ message: Message, from transport: TransportType) {
        // Mostrar mensaje recibido en UI
        print("Mensaje recibido vía \(transport): \(message.data.count) bytes")
    }

    @objc func sendTestMessage() {
        let testMessage = Message(
            id: MessageID(),
            data: "Hola desde coordinación de transportes".data(using: .utf8)!,
            metadata: ["type": "test"]
        )

        Task {
            do {
                try await coordinator.sendMessage(testMessage, priority: .normal)
                showSuccess("Mensaje enviado")
            } catch {
                showError("Error enviando mensaje: \(error.localizedDescription)")
            }
        }
    }

    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Éxito", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

## Notas Adicionales

- Implementa timeouts apropiados para cada tipo de transporte
- Considera el impacto en batería de mantener múltiples conexiones activas
- Implementa compresión automática para mensajes grandes
- Maneja correctamente la fragmentación de mensajes
- Proporciona indicadores visuales del estado de cada transporte
- Implementa políticas de reintento inteligentes
- Considera el costo de datos para transportes celulares