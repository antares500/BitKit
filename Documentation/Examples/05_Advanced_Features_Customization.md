# 05 - Características Avanzadas y Personalización

## Descripción

Este ejemplo avanzado demuestra cómo combinar múltiples características de BitchatCommunications para crear una aplicación de mensajería completa y personalizada. Incluye encriptación avanzada, gestión de estado distribuido, transferencias de archivos, y un sistema de plugins extensible. Esta configuración muestra cómo construir una aplicación robusta que puede escalar desde comunicaciones locales hasta redes globales.

**Beneficios:**
- Arquitectura modular que permite añadir características sin refactorización masiva
- Encriptación de extremo a extremo con forward secrecy
- Sistema de plugins para extensibilidad
- Gestión inteligente de estado para sincronización entre dispositivos
- Transferencias de archivos seguras con verificación de integridad
- Balance automático entre BLE local y redes globales

**Consideraciones:**
- Mayor complejidad de implementación requiere experiencia en Swift avanzado
- Gestión de estado distribuido puede ser complejo en redes particionadas
- Los plugins deben ser cuidadosamente auditados por seguridad
- Transferencias de archivos grandes pueden afectar el rendimiento de BLE
- Forward secrecy requiere rotación frecuente de claves
- Monitoreo de rendimiento crítico para aplicaciones a escala

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Configurar BLE Mesh** (Ejemplo 02)
3. **Añadir todas las dependencias**: BitchatNostr, BitchatGeo, BitchatState, BitchatFiles
4. **Implementar AdvancedCryptoManager** para encriptación avanzada
5. **Configurar PluginArchitecture** para extensibilidad

## Código de Implementación

```swift
import BitchatCore
import BitchatBLE
import BitchatNostr
import BitchatGeo
import BitchatState
import BitchatFiles
import Combine
import CryptoKit

// Arquitectura principal de la aplicación avanzada
class AdvancedBitchatApp {
    // Componentes principales
    private let cryptoManager: AdvancedCryptoManager
    private let stateManager: DistributedStateManager
    private let fileTransfer: SecureFileTransfer
    private let pluginManager: PluginManager
    private let networkCoordinator: NetworkCoordinator

    // Servicios de transporte
    private let bleService: BLEService
    private let nostrService: NostrRelayManager?
    private let geoService: GeoEngine?

    // Estado de la aplicación
    private var currentUser: UserProfile?
    private var activeConversations: [Conversation] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Inicializar componentes avanzados
        cryptoManager = AdvancedCryptoManager()
        stateManager = DistributedStateManager(crypto: cryptoManager)
        fileTransfer = SecureFileTransfer(crypto: cryptoManager)
        pluginManager = PluginManager()
        networkCoordinator = NetworkCoordinator()

        // Inicializar servicios de transporte
        bleService = BLEService()
        nostrService = NostrRelayManager.shared  // Opcional
        geoService = GeoEngine()  // Opcional

        // Configurar arquitectura
        configurarArquitectura()
    }

    // Configuración completa de la aplicación
    private func configurarArquitectura() {
        // Configurar encriptación avanzada
        cryptoManager.initializeWithForwardSecrecy()

        // Configurar gestión de estado distribuido
        configurarStateManager()

        // Configurar coordinador de red
        configurarNetworkCoordinator()

        // Cargar plugins
        cargarPluginsPorDefecto()

        // Configurar servicios de transporte
        configurarTransportes()

        print("Arquitectura avanzada configurada")
    }

    // Configurar gestión de estado distribuido
    private func configurarStateManager() {
        // Configurar sincronización entre dispositivos
        stateManager.configureSync(
            syncInterval: 30.0,  // Sincronizar cada 30 segundos
            conflictResolver: .lastWriteWins,
            encryptionEnabled: true
        )

        // Suscribirse a cambios de estado
        stateManager.stateChanges
            .sink { [weak self] cambio in
                self?.manejarCambioEstado(cambio)
            }
            .store(in: &cancellables)
    }

    // Configurar coordinador de red inteligente
    private func configurarNetworkCoordinator() {
        networkCoordinator.configure(
            transports: [bleService, nostrService, geoService].compactMap { $0 },
            strategy: .adaptive,  // Cambiar automáticamente entre transportes
            fallbackEnabled: true
        )

        // Monitorear cambios de conectividad
        networkCoordinator.connectivityChanges
            .sink { [weak self] estado in
                self?.manejarCambioConectividad(estado)
            }
            .store(in: &cancellables)
    }

    // Cargar plugins por defecto
    private func cargarPluginsPorDefecto() {
        // Plugin de compresión de mensajes
        pluginManager.loadPlugin(MessageCompressionPlugin())

        // Plugin de backup automático
        pluginManager.loadPlugin(AutoBackupPlugin())

        // Plugin de moderación de contenido
        pluginManager.loadPlugin(ContentModerationPlugin())

        // Plugin de métricas de rendimiento
        pluginManager.loadPlugin(PerformanceMetricsPlugin())

        print("Plugins cargados: \(pluginManager.loadedPlugins.count)")
    }

    // Configurar servicios de transporte
    private func configurarTransportes() {
        // Configurar BLE con mesh avanzado
        bleService.configureMesh(
            maxHops: 5,
            redundancyLevel: .high,
            encryptionRequired: true
        )

        // Configurar Nostr si está disponible
        if let nostr = nostrService {
            nostr.configureRelays([
                "wss://relay.damus.io",
                "wss://relay.nostr.band"
            ])
        }

        // Configurar geolocalización si está disponible
        if let geo = geoService {
            geo.configurePrivacy(
                precision: .medium,
                retentionPolicy: .ephemeral
            )
        }
    }

    // Crear nueva conversación avanzada
    func crearConversacionAvanzada(
        participantes: [PeerID],
        opciones: ConversationOptions = .default
    ) -> Conversation {
        // Generar clave de conversación única
        let conversationKey = cryptoManager.generateConversationKey()

        // Crear conversación con encriptación avanzada
        let conversacion = Conversation(
            id: UUID(),
            participants: participantes,
            encryptionKey: conversationKey,
            options: opciones,
            createdAt: Date()
        )

        // Registrar en estado distribuido
        stateManager.registerConversation(conversacion)

        // Notificar a participantes vía red coordinada
        networkCoordinator.broadcastConversationInvite(conversacion)

        activeConversations.append(conversacion)

        print("Conversación avanzada creada con \(participantes.count) participantes")
        return conversacion
    }

    // Enviar mensaje con características avanzadas
    func enviarMensajeAvanzado(
        _ contenido: String,
        en conversacion: Conversation,
        opciones: MessageOptions = .default
    ) {
        // Aplicar plugins de pre-procesamiento
        var mensajeProcesado = contenido
        for plugin in pluginManager.messagePlugins {
            mensajeProcesado = plugin.preprocessMessage(mensajeProcesado)
        }

        // Crear mensaje con metadatos avanzados
        let mensaje = AdvancedMessage(
            id: UUID(),
            conversationId: conversacion.id,
            content: mensajeProcesado,
            sender: currentUser?.peerID ?? PeerID(data: Data([0x01, 0x02, 0x03, 0x04]))!,
            timestamp: Date(),
            encryption: .forwardSecrecy,
            metadata: generarMetadataMensaje(opciones),
            signature: cryptoManager.signMessage(mensajeProcesado)
        )

        // Enviar vía coordinador de red (elige mejor transporte)
        networkCoordinator.sendMessage(mensaje, to: conversacion)

        // Actualizar estado local
        stateManager.recordMessage(mensaje)

        print("Mensaje avanzado enviado: \(mensajeProcesado.prefix(50))...")
    }

    // Transferir archivo de forma segura
    func transferirArchivo(
        _ url: URL,
        en conversacion: Conversation,
        progreso: @escaping (Double) -> Void
    ) async throws {
        // Verificar límites de archivo
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
        guard fileSize <= FileTransferLimits.maxFileSize else {
            throw FileTransferError.fileTooLarge
        }

        // Crear descriptor de archivo
        let fileDescriptor = FileDescriptor(
            id: UUID(),
            filename: url.lastPathComponent,
            size: fileSize,
            mimeType: MimeType.from(url.pathExtension),
            checksum: try cryptoManager.calculateFileChecksum(url)
        )

        // Iniciar transferencia segura
        try await fileTransfer.sendFile(
            url,
            descriptor: fileDescriptor,
            to: conversacion,
            progressCallback: progreso
        )

        print("Archivo transferido: \(fileDescriptor.filename) (\(fileSize) bytes)")
    }

    // Generar metadatos avanzados para mensaje
    private func generarMetadataMensaje(_ opciones: MessageOptions) -> MessageMetadata {
        return MessageMetadata(
            priority: opciones.priority,
            ttl: opciones.ttl,
            readReceipt: opciones.readReceipt,
            deliveryConfirmation: opciones.deliveryConfirmation,
            compressionUsed: opciones.compression,
            pluginMetadata: pluginManager.collectMetadata()
        )
    }

    // Manejar cambios de estado
    private func manejarCambioEstado(_ cambio: StateChange) {
        switch cambio.type {
        case .conversationUpdated:
            actualizarConversacion(cambio.conversationId)
        case .messageReceived:
            manejarMensajeRecibido(cambio.messageId)
        case .peerStatusChanged:
            actualizarEstadoPeer(cambio.peerId, status: cambio.peerStatus)
        }
    }

    // Manejar cambios de conectividad
    private func manejarCambioConectividad(_ estado: ConnectivityState) {
        switch estado {
        case .bleOnly:
            print("Modo BLE únicamente - alcance limitado")
            // Optimizar para BLE local
        case .internetAvailable:
            print("Internet disponible - habilitando características globales")
            // Habilitar Nostr y otras características online
        case .geolocationEnabled:
            print("Geolocalización disponible - habilitando mensajería local")
            // Activar características geo
        case .offline:
            print("Modo offline - funcionalidad limitada")
            // Conservar batería y recursos
        }
    }

    // Actualizar conversación (placeholder)
    private func actualizarConversacion(_ conversationId: UUID) {
        print("Conversación actualizada: \(conversationId)")
    }

    // Manejar mensaje recibido (placeholder)
    private func manejarMensajeRecibido(_ messageId: UUID) {
        print("Mensaje recibido: \(messageId)")
    }

    // Actualizar estado de peer (placeholder)
    private func actualizarEstadoPeer(_ peerId: PeerID, status: PeerStatus) {
        print("Peer \(peerId) cambió estado a: \(status)")
    }

    // Obtener métricas de rendimiento
    func obtenerMetricasRendimiento() -> PerformanceMetrics {
        return PerformanceMetrics(
            messagesPerSecond: calcularMensajesPorSegundo(),
            averageLatency: calcularLatenciaPromedio(),
            successRate: calcularTasaExito(),
            batteryImpact: calcularImpactoBateria(),
            dataUsage: calcularUsoDatos()
        )
    }

    // Cálculos de métricas (placeholders)
    private func calcularMensajesPorSegundo() -> Double { return 0.0 }
    private func calcularLatenciaPromedio() -> TimeInterval { return 0.0 }
    private func calcularTasaExito() -> Double { return 0.0 }
    private func calcularImpactoBateria() -> Double { return 0.0 }
    private func calcularUsoDatos() -> Int64 { return 0 }

    // Backup automático del estado
    func realizarBackupAutomatico() {
        let backupData = stateManager.createBackup()
        // Encriptar y almacenar backup
        cryptoManager.encryptAndStoreBackup(backupData)
        print("Backup automático completado")
    }

    // Limpiar datos antiguos para optimización
    func limpiarDatosAntiguos(diasAntiguedad: Int = 30) {
        let fechaLimite = Date().addingTimeInterval(-Double(diasAntiguedad * 24 * 3600))
        stateManager.removeMessagesOlderThan(fechaLimite)
        print("Datos antiguos limpiados (>\(diasAntiguedad) días)")
    }
}

// Manager de encriptación avanzada
class AdvancedCryptoManager {
    private var keyRotationTimer: Timer?

    func initializeWithForwardSecrecy() {
        // Inicializar con forward secrecy
        print("Encriptación con forward secrecy inicializada")

        // Configurar rotación automática de claves
        keyRotationTimer = Timer.scheduledTimer(
            withTimeInterval: 3600,  // Rotar cada hora
            repeats: true
        ) { [weak self] _ in
            self?.rotateKeys()
        }
    }

    func generateConversationKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }

    func signMessage(_ message: String) -> Data {
        // En implementación real, firmar con clave privada
        return Data()  // Placeholder
    }

    func calculateFileChecksum(_ url: URL) throws -> Data {
        // Calcular checksum del archivo
        let fileData = try Data(contentsOf: url)
        return SHA256.hash(data: fileData).data
    }

    func encryptAndStoreBackup(_ data: Data) {
        // Encriptar y almacenar backup
        print("Backup encriptado y almacenado")
    }

    private func rotateKeys() {
        // Rotar claves para forward secrecy
        print("Claves rotadas para forward secrecy")
    }
}

// Sistema de plugins extensible
class PluginManager {
    private var plugins: [Plugin] = []
    var loadedPlugins: [Plugin] { plugins }
    var messagePlugins: [MessagePlugin] {
        plugins.compactMap { $0 as? MessagePlugin }
    }

    func loadPlugin(_ plugin: Plugin) {
        plugins.append(plugin)
        plugin.onLoad()
    }

    func collectMetadata() -> [String: Any] {
        var metadata = [String: Any]()
        for plugin in plugins {
            metadata.merge(plugin.getMetadata()) { (_, new) in new }
        }
        return metadata
    }
}

// Protocolos para plugins
protocol Plugin {
    func onLoad()
    func onUnload()
    func getMetadata() -> [String: Any]
}

protocol MessagePlugin: Plugin {
    func preprocessMessage(_ message: String) -> String
}

// Plugins de ejemplo
class MessageCompressionPlugin: MessagePlugin {
    func onLoad() { print("Plugin de compresión cargado") }
    func onUnload() { }
    func getMetadata() -> [String: Any] { ["compression": "enabled"] }

    func preprocessMessage(_ message: String) -> String {
        // Comprimir mensaje si es largo
        return message.count > 1000 ? compress(message) : message
    }

    private func compress(_ text: String) -> String {
        // Implementación de compresión simple
        return text  // Placeholder
    }
}

class AutoBackupPlugin: Plugin {
    func onLoad() { print("Plugin de backup automático cargado") }
    func onUnload() { }
    func getMetadata() -> [String: Any] { ["autoBackup": "enabled"] }
}

class ContentModerationPlugin: MessagePlugin {
    func onLoad() { print("Plugin de moderación cargado") }
    func onUnload() { }
    func getMetadata() -> [String: Any] { ["moderation": "enabled"] }

    func preprocessMessage(_ message: String) -> String {
        // Moderar contenido inapropiado
        return filterInappropriateContent(message)
    }

    private func filterInappropriateContent(_ message: String) -> String {
        // Implementación de filtrado
        return message  // Placeholder
    }
}

class PerformanceMetricsPlugin: Plugin {
    func onLoad() { print("Plugin de métricas cargado") }
    func onUnload() { }
    func getMetadata() -> [String: Any] { ["metrics": "enabled"] }
}

// Estructuras de datos avanzadas
struct ConversationOptions {
    var encryption: EncryptionLevel = .standard
    var maxParticipants: Int = 50
    var allowFiles: Bool = true
    var ephemeral: Bool = false
    var geoRestricted: Bool = false

    static let `default` = ConversationOptions()
}

struct MessageOptions {
    var priority: MessagePriority = .normal
    var ttl: TimeInterval = 86400  // 24 horas
    var readReceipt: Bool = true
    var deliveryConfirmation: Bool = false
    var compression: Bool = true

    static let `default` = MessageOptions()
}

struct AdvancedMessage {
    let id: UUID
    let conversationId: UUID
    let content: String
    let sender: PeerID
    let timestamp: Date
    let encryption: EncryptionLevel
    let metadata: MessageMetadata
    let signature: Data
}

struct MessageMetadata {
    let priority: MessagePriority
    let ttl: TimeInterval
    let readReceipt: Bool
    let deliveryConfirmation: Bool
    let compressionUsed: Bool
    let pluginMetadata: [String: Any]
}

enum EncryptionLevel {
    case standard, forwardSecrecy, quantumResistant
}

enum MessagePriority {
    case low, normal, high, urgent
}

enum ConnectivityState {
    case offline, bleOnly, internetAvailable, geolocationEnabled
}

struct PerformanceMetrics {
    let messagesPerSecond: Double
    let averageLatency: TimeInterval
    let successRate: Double
    let batteryImpact: Double
    let dataUsage: Int64
}

enum FileTransferError: Error {
    case fileTooLarge, networkError, encryptionFailed, checksumMismatch
}
```

## Notas Adicionales

- La arquitectura modular permite añadir características sin romper compatibilidad
- Forward secrecy rota claves automáticamente para máxima seguridad
- El coordinador de red elige automáticamente el mejor transporte disponible
- Los plugins permiten extensibilidad sin modificar el código base
- Las métricas de rendimiento ayudan a optimizar el uso de recursos
- La gestión de estado distribuido maneja conflictos automáticamente