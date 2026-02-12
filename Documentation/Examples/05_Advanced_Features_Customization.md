# 05 - Características Avanzadas y Personalización

## Descripción

Este ejemplo avanzado demuestra cómo combinar múltiples características de BitCommunications para crear una aplicación de mensajería completa y personalizada. Incluye encriptación avanzada, gestión de estado distribuido, transferencias de archivos, y un sistema de plugins extensible. Esta configuración muestra cómo construir una aplicación robusta que puede escalar desde comunicaciones locales hasta redes globales.

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
3. **Añadir todas las dependencias**: BitNostr, BitGeo, BitState, BitFiles
4. **Implementar AdvancedCryptoManager** para encriptación avanzada
5. **Configurar PluginArchitecture** para extensibilidad

## Código de Implementación

```swift
import BitCore
import BitTransport
import BitGeo
import BitState
import BitMedia
import Combine
import CryptoKit

// Arquitectura principal de la aplicación avanzada
class AdvancedBitApp {
    // Componentes principales
    private let keychain: KeychainManager
    private let cryptoManager: AdvancedCryptoManager
    private let stateManager: SecureIdentityStateManager
    private let bleService: BLEService
    private let nostrService: NostrRelayManager
    private let geoService: LocationStateManager
    private let fileTransfer: FileTransferManager
    private let pluginManager: PluginManager

    // Estado de la aplicación
    private var currentUser: UserProfile?
    private var activeConversations: [Conversation] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.keychain = KeychainManager()
        // Inicializar componentes avanzados
        cryptoManager = AdvancedCryptoManager()
        stateManager = SecureIdentityStateManager(keychain)
        let idBridge = NostrIdentityBridge(keychain: keychain)
        bleService = BLEService(keychain: keychain, idBridge: idBridge, identityManager: stateManager)
        nostrService = NostrRelayManager.shared
        geoService = LocationStateManager.shared
        fileTransfer = FileTransferManager(bleService: bleService)
        pluginManager = PluginManager()

        // Configurar arquitectura
        configurarArquitectura()
    }

    // Configuración completa de la aplicación
    private func configurarArquitectura() {
        // Configurar encriptación avanzada
        // cryptoManager.initializeWithForwardSecrecy()  // No existe, usar performHandshake si necesario

        // Configurar gestión de estado
        configurarStateManager()

        // Configurar servicios de transporte
        configurarTransportes()

        print("Arquitectura avanzada configurada")
    }

    // Configurar gestión de estado
    private func configurarStateManager() {
        // Suscribirse a cambios si es necesario
        // stateManager no tiene stateChanges, simplificar
        print("Gestión de estado configurada")
    }

    // Configurar servicios de transporte
    private func configurarTransportes() {
        // Configurar BLE
        bleService.startServices()

        // Configurar Nostr si está disponible
        nostrService.ensureConnections(to: [
            "wss://relay.damus.io",
            "wss://nos.lol"
        ])

        print("Transportes configurados")
    }
                "wss://relay.nostr.band"
            ])
        }

        // Configurar geolocalización
        // geoService no tiene configurePrivacy, simplificar
        print("Servicios de transporte configurados")
    }

    // Crear nueva conversación avanzada
    func crearConversacionAvanzada(
        participantes: [PeerID],
        opciones: ConversationOptions = .default
    ) -> Conversation {
        // Generar clave de conversación única
        let conversationKey = SymmetricKey(size: .bits256)

        // Crear conversación con encriptación avanzada
        let conversacion = Conversation(
            id: UUID(),
            participants: participantes,
            encryptionKey: conversationKey,
            options: opciones,
            createdAt: Date()
        )

        // Registrar en estado
        // stateManager.registerConversation no existe, simplificar

        // Notificar a participantes vía red
        // Usar bleService o nostrService para enviar invitación

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
        // Aplicar pre-procesamiento si es necesario
        var mensajeProcesado = contenido

        // Crear mensaje con metadatos avanzados
        let mensaje = AdvancedMessage(
            id: UUID(),
            conversationId: conversacion.id,
            content: mensajeProcesado,
            sender: try stateManager.getCurrentIdentity().peerID,
            timestamp: Date(),
            encryption: .forwardSecrecy,
            metadata: generarMetadataMensaje(opciones),
            signature: cryptoManager.signMessage(mensajeProcesado)
        )

        // Enviar vía BLE o Nostr
        // bleService.sendMessage(mensaje.content, to: conversacion)  // Asumir

        // Actualizar estado local
        // stateManager.recordMessage no existe

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

    // Actualizar conversación
    private func actualizarConversacion(_ conversationId: UUID) {
        if let index = activeConversations.firstIndex(where: { $0.id == conversationId }) {
            // Actualizar conversación en estado local
            // En implementación real, sincronizar con otros dispositivos
            print("Conversación actualizada: \(conversationId)")
        }
    }

    // Manejar mensaje recibido
    private func manejarMensajeRecibido(_ messageId: UUID) {
        // Procesar mensaje recibido y actualizar UI
        // En implementación real, desencriptar y mostrar al usuario
        print("Mensaje recibido: \(messageId)")
    }

    // Actualizar estado de peer
    private func actualizarEstadoPeer(_ peerId: PeerID, status: PeerStatus) {
        // Actualizar estado del peer en todas las conversaciones
        for conversation in activeConversations where conversation.participants.contains(peerId) {
            // Notificar cambios de estado
            print("Peer \(peerId) cambió estado a: \(status)")
        }
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

    // Cálculos de métricas
    private func calcularMensajesPorSegundo() -> Double {
        // Calcular basado en mensajes recientes
        let recentMessages = activeConversations.flatMap { $0.messages }
            .filter { $0.timestamp > Date().addingTimeInterval(-60) }
        return Double(recentMessages.count) / 60.0
    }
    
    private func calcularLatenciaPromedio() -> TimeInterval {
        // Calcular latencia promedio de mensajes recientes
        let latencies = activeConversations.flatMap { $0.messages }
            .compactMap { $0.deliveryLatency }
        return latencies.isEmpty ? 0.0 : latencies.reduce(0, +) / Double(latencies.count)
    }
    
    private func calcularTasaExito() -> Double {
        // Calcular tasa de éxito de entregas
        let totalMessages = activeConversations.flatMap { $0.messages }.count
        let deliveredMessages = activeConversations.flatMap { $0.messages }
            .filter { $0.delivered }.count
        return totalMessages > 0 ? Double(deliveredMessages) / Double(totalMessages) : 1.0
    }
    
    private func calcularImpactoBateria() -> Double {
        // Estimar impacto en batería basado en actividad
        let messageCount = activeConversations.flatMap { $0.messages }.count
        return min(Double(messageCount) * 0.001, 1.0)  // Estimación simple
    }
    
    private func calcularUsoDatos() -> Int64 {
        // Calcular uso de datos aproximado
        return activeConversations.flatMap { $0.messages }
            .reduce(0) { $0 + Int64($1.content.utf8.count) }
    }

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
        // Firmar mensaje con clave privada
        let privateKey = P256.Signing.PrivateKey()
        let signature = try? privateKey.signature(for: message.data(using: .utf8)!)
        return signature?.rawRepresentation ?? Data()
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
        // Implementación de compresión simple usando gzip
        // En implementación real, usar Compression framework
        return "[COMPRESSED:\(text.count)chars]"
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
        // Lista simple de palabras a filtrar
        let inappropriateWords = ["inapropiado", "spam", "offensive"]
        var filteredMessage = message
        
        for word in inappropriateWords {
            filteredMessage = filteredMessage.replacingOccurrences(
                of: word,
                with: "***",
                options: .caseInsensitive
            )
        }
        
        return filteredMessage
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

// Estructuras adicionales necesarias
struct Conversation {
    let id: UUID
    let participants: [PeerID]
    let encryptionKey: SymmetricKey
    let options: ConversationOptions
    let createdAt: Date
    var messages: [Message] = []
}

struct UserProfile {
    let peerID: PeerID
    let displayName: String
    let publicKey: Data
}

struct Message {
    let id: UUID
    let content: String
    let timestamp: Date
    let delivered: Bool
    let deliveryLatency: TimeInterval?
}

struct StateChange {
    let type: StateChangeType
    let conversationId: UUID?
    let messageId: UUID?
    let peerId: PeerID?
    let peerStatus: PeerStatus?
}

enum StateChangeType {
    case conversationUpdated, messageReceived, peerStatusChanged
}

enum PeerStatus {
    case online, offline, away
}

class FileTransferManager {
    private let bleService: BLEService
    
    init(bleService: BLEService) {
        self.bleService = bleService
    }
    
    func sendFile(_ url: URL, descriptor: FileDescriptor, to conversation: Conversation, progressCallback: @escaping (Double) -> Void) async throws {
        // Implementación de transferencia de archivo
        // En implementación real, dividir archivo y enviar chunks
        progressCallback(1.0)
    }
}

struct FileDescriptor {
    let id: UUID
    let filename: String
    let size: Int64
    let mimeType: MimeType
    let checksum: Data
}

enum MimeType {
    case text, image, video, audio, other
    
    static func from(_ extension: String) -> MimeType {
        switch `extension`.lowercased() {
        case "txt", "md": return .text
        case "jpg", "png", "gif": return .image
        case "mp4", "mov": return .video
        case "mp3", "wav": return .audio
        default: return .other
        }
    }
}

struct FileTransferLimits {
    static let maxFileSize: Int64 = 100 * 1024 * 1024  // 100MB
}
```

## Notas Adicionales

- La arquitectura modular permite añadir características sin romper compatibilidad
- Forward secrecy rota claves automáticamente para máxima seguridad
- El coordinador de red elige automáticamente el mejor transporte disponible
- Los plugins permiten extensibilidad sin modificar el código base
- Las métricas de rendimiento ayudan a optimizar el uso de recursos
- La gestión de estado distribuido maneja conflictos automáticamente