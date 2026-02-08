import Foundation

/// Centralized knobs for transport- and UI-related limits.
/// Keep values aligned with existing behavior when replacing magic numbers.
/// Todos los valores son configurables en tiempo de ejecución.
public class TransportConfig {
    /// Singleton compartido con configuración por defecto
    public static var shared = TransportConfig()

    // MARK: - BLE / Protocol

    /// Tamaño de fragmento BLE por defecto (~512 MTU menos overhead del protocolo)
    /// - Default: 469 bytes
    /// - Rango recomendado: 128 - 512
    public var bleDefaultFragmentSize: Int = 469

    /// TTL por defecto para flooding en mesh
    /// - Default: 7 hops
    /// - Rango recomendado: 3 - 10
    public var messageTTLDefault: UInt8 = 7

    /// Límite de ensamblajes de fragmentos concurrentes
    /// - Default: 128
    public var bleMaxInFlightAssemblies: Int = 128

    /// Umbral de alto grado de conectividad (para TTL adaptativo)
    /// - Default: 6 peers
    public var bleHighDegreeThreshold: Int = 6

    /// Límite de transferencias grandes simultáneas
    /// - Default: 2
    public var bleMaxConcurrentTransfers: Int = 2

    /// Delay mínimo para reenvío de fragmentos (ms)
    /// - Default: 8ms
    public var bleFragmentRelayMinDelayMs: Int = 8

    /// Delay máximo para jitter en reenvío de fragmentos (ms)
    /// - Default: 25ms
    public var bleFragmentRelayMaxDelayMs: Int = 25

    /// TTL máximo para fragmentos (contiene floods)
    /// - Default: 5 hops
    public var bleFragmentRelayTtlCap: UInt8 = 5

    // BLE operational delays
    public var bleInitialAnnounceDelaySeconds: TimeInterval = 0.6
    public var bleConnectTimeoutSeconds: TimeInterval = 8.0
    public var bleRestartScanDelaySeconds: TimeInterval = 0.1
    public var blePostSubscribeAnnounceDelaySeconds: TimeInterval = 0.05
    public var blePostAnnounceDelaySeconds: TimeInterval = 0.1
    public var bleReconnectLogDebounceSeconds: TimeInterval = 5.0
    public var bleDisconnectNotifyDebounceSeconds: TimeInterval = 1.0
    public var bleDirectedSpoolWindowSeconds: TimeInterval = 30.0

    // BLE rate limiting
    public var bleSubscriptionRateLimitWindowSeconds: TimeInterval = 60.0
    public var bleSubscriptionRateLimitMinSeconds: TimeInterval = 2.0
    public var bleSubscriptionRateLimitMaxAttempts: Int = 5
    public var bleSubscriptionRateLimitBackoffFactor: Double = 2.0
    public var bleSubscriptionRateLimitMaxBackoffSeconds: TimeInterval = 300.0

    // BLE connection management
    public var bleWeakLinkCooldownSeconds: TimeInterval = 30.0
    public var bleWeakLinkRSSICutoff: Int = -70
    public var bleForceAnnounceMinIntervalSeconds: TimeInterval = 2.0

    // MARK: - UI / User Experience

    /// Límite de mensajes en cola de envío
    /// - Default: 1000
    public var uiMaxQueuedMessages: Int = 1000

    /// Límite de mensajes en historial de chat
    /// - Default: 10000
    public var uiMaxChatHistoryMessages: Int = 10000

    /// Límite de peers en lista de peers conocidos
    /// - Default: 1000
    public var uiMaxKnownPeers: Int = 1000

    /// Timeout para operaciones de UI (segundos)
    /// - Default: 30 segundos
    public var uiOperationTimeoutSeconds: TimeInterval = 30.0

    // MARK: - Timers / Timeouts

    /// Timeout para sincronización de estado (segundos)
    /// - Default: 30 segundos
    public var syncStateTimeoutSeconds: TimeInterval = 30.0

    /// Intervalo de heartbeat para mantener conexiones (segundos)
    /// - Default: 60 segundos
    public var heartbeatIntervalSeconds: TimeInterval = 60.0

    /// Timeout para operaciones de red (segundos)
    /// - Default: 10 segundos
    public var networkOperationTimeoutSeconds: TimeInterval = 10.0

    // MARK: - Location / Geo

    /// Radio de búsqueda geográfica por defecto (metros)
    /// - Default: 100 metros
    public var geoDefaultSearchRadiusMeters: Double = 100.0

    /// Precisión mínima requerida para ubicación (metros)
    /// - Default: 10 metros
    public var geoMinAccuracyMeters: Double = 10.0

    /// Timeout para obtención de ubicación (segundos)
    /// - Default: 30 segundos
    public var geoLocationTimeoutSeconds: TimeInterval = 30.0

    /// Intervalo de actualización de ubicación (segundos)
    /// - Default: 300 segundos (5 minutos)
    public var geoUpdateIntervalSeconds: TimeInterval = 300.0

    // MARK: - Nostr

    /// Timeout para conexiones Nostr (segundos)
    /// - Default: 10 segundos
    public var nostrConnectionTimeoutSeconds: TimeInterval = 10.0

    /// Límite de relays Nostr por defecto
    /// - Default: 10
    public var nostrMaxRelays: Int = 10

    /// Intervalo de reintento para relays Nostr (segundos)
    /// - Default: 30 segundos
    public var nostrRelayRetryIntervalSeconds: TimeInterval = 30.0

    // MARK: - Compression / Performance

    /// Nivel de compresión por defecto (0-9, donde 9 es máximo)
    /// - Default: 6 (buen balance velocidad/compresión)
    public var compressionLevel: Int = 6

    /// Tamaño mínimo para comprimir (bytes)
    /// - Default: 1024 bytes
    public var compressionMinSizeBytes: Int = 1024

    /// Tamaño máximo de buffer de compresión (bytes)
    /// - Default: 1MB
    public var compressionMaxBufferSizeBytes: Int = 1_048_576

    // MARK: - File Transfer

    /// Tamaño máximo de archivo para transferencias (bytes)
    /// - Default: 100MB
    public var fileTransferMaxSizeBytes: Int = 100_000_000

    /// Timeout para transferencias de archivos (segundos)
    /// - Default: 300 segundos (5 minutos)
    public var fileTransferTimeoutSeconds: TimeInterval = 300.0

    /// Límite de transferencias concurrentes
    /// - Default: 3
    public var fileTransferMaxConcurrent: Int = 3

    // MARK: - Validation

    /// Método de validación de configuración
    public func validate() throws {
        // BLE validation
        guard bleDefaultFragmentSize >= 128 && bleDefaultFragmentSize <= 512 else {
            throw ValidationError.invalidValue("bleDefaultFragmentSize must be between 128-512")
        }
        guard messageTTLDefault >= 3 && messageTTLDefault <= 10 else {
            throw ValidationError.invalidValue("messageTTLDefault must be between 3-10")
        }
        guard bleMaxInFlightAssemblies > 0 && bleMaxInFlightAssemblies <= 1000 else {
            throw ValidationError.invalidValue("bleMaxInFlightAssemblies must be between 1-1000")
        }

        // UI validation
        guard uiMaxQueuedMessages > 0 && uiMaxQueuedMessages <= 10000 else {
            throw ValidationError.invalidValue("uiMaxQueuedMessages must be between 1-10000")
        }
        guard uiMaxChatHistoryMessages >= 1000 && uiMaxChatHistoryMessages <= 100000 else {
            throw ValidationError.invalidValue("uiMaxChatHistoryMessages must be between 1000-100000")
        }

        // Compression validation
        guard compressionLevel >= 0 && compressionLevel <= 9 else {
            throw ValidationError.invalidValue("compressionLevel must be between 0-9")
        }
        guard compressionMinSizeBytes >= 64 else {
            throw ValidationError.invalidValue("compressionMinSizeBytes must be at least 64")
        }

        // File transfer validation
        guard fileTransferMaxSizeBytes >= 1_048_576 && fileTransferMaxSizeBytes <= 1_073_741_824 else {
            throw ValidationError.invalidValue("fileTransferMaxSizeBytes must be between 1MB-1GB")
        }
    }

    /// Errores de validación
    public enum ValidationError: Error {
        case invalidValue(String)
    }
}