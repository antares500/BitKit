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
    public var blePostAnnounceDelaySeconds: TimeInterval = 0.05
    public var bleSubscriptionRateLimitMinSeconds: TimeInterval = 0.5
    public var bleSubscriptionRateLimitWindowSeconds: TimeInterval = 10.0
    public var bleReconnectLogDebounceSeconds: TimeInterval = 5.0
    public var bleDisconnectNotifyDebounceSeconds: TimeInterval = 1.0
    public var bleDirectedSpoolWindowSeconds: TimeInterval = 30.0

    // MARK: - UI / User Experience

    /// Límite de mensajes en cola de envío
    /// - Default: 1000
    public var uiMaxQueuedMessages: Int = 1000

    /// Límite de mensajes en cola de recepción
    /// - Default: 1000
    public var uiMaxQueuedReceivedMessages: Int = 1000

    /// Límite de mensajes en cola de retransmisión
    /// - Default: 100
    public var uiMaxQueuedRetransmissions: Int = 100

    /// Límite de mensajes en cola de notificaciones
    /// - Default: 100
    public var uiMaxQueuedNotifications: Int = 100

    /// Límite de mensajes en cola de archivos
    /// - Default: 50
    public var uiMaxQueuedFileMessages: Int = 50

    /// Límite de mensajes en cola de ubicación
    /// - Default: 100
    public var uiMaxQueuedLocationMessages: Int = 100

    /// Límite de mensajes en cola de estado
    /// - Default: 50
    public var uiMaxQueuedStatusMessages: Int = 50

    /// Límite de mensajes en cola de moderación
    /// - Default: 50
    public var uiMaxQueuedModerationMessages: Int = 50

    /// Límite de mensajes en cola de analíticas
    /// - Default: 100
    public var uiMaxQueuedAnalyticsMessages: Int = 100

    /// Límite de mensajes en cola de comunidad
    /// - Default: 100
    public var uiMaxQueuedCommunityMessages: Int = 100

    /// Límite de mensajes en cola de identidad
    /// - Default: 50
    public var uiMaxQueuedIdentityMessages: Int = 50

    /// Límite de mensajes en cola de verificación
    /// - Default: 50
    public var uiMaxQueuedVerificationMessages: Int = 50

    /// Límite de mensajes en cola de transporte
    /// - Default: 100
    public var uiMaxQueuedTransportMessages: Int = 100

    /// Límite de mensajes en cola de sincronización
    /// - Default: 100
    public var uiMaxQueuedSyncMessages: Int = 100

    /// Límite de mensajes en cola de estado
    /// - Default: 50
    public var uiMaxQueuedStateMessages: Int = 50

    /// Límite de mensajes en cola de Tor
    /// - Default: 50
    public var uiMaxQueuedTorMessages: Int = 50

    /// Límite de mensajes en cola de Nostr
    /// - Default: 100
    public var uiMaxQueuedNostrMessages: Int = 100

    /// Límite de mensajes en cola de Geo
    /// - Default: 100
    public var uiMaxQueuedGeoMessages: Int = 100

    /// Límite de mensajes en cola de Media
    /// - Default: 50
    public var uiMaxQueuedMediaMessages: Int = 50

    /// Límite de mensajes en cola de Noise
    /// - Default: 50
    public var uiMaxQueuedNoiseMessages: Int = 50

    /// Límite de mensajes en cola de Utils
    /// - Default: 50
    public var uiMaxQueuedUtilsMessages: Int = 50

    /// Límite de mensajes en cola de Reliability
    /// - Default: 100
    public var uiMaxQueuedReliabilityMessages: Int = 100

    /// Límite de mensajes en cola de Routing
    /// - Default: 100
    public var uiMaxQueuedRoutingMessages: Int = 100

    /// Límite de mensajes en cola de Sync
    /// - Default: 100
    public var uiMaxQueuedSyncMessages2: Int = 100

    /// Límite de mensajes en cola de Verification
    /// - Default: 50
    public var uiMaxQueuedVerificationMessages2: Int = 50

    // MARK: - Timers / Timeouts

    /// Timeout para operaciones de red
    /// - Default: 30 segundos
    public var networkTimeoutSeconds: TimeInterval = 30.0

    /// Timeout para operaciones de archivo
    /// - Default: 300 segundos (5 minutos)
    public var fileOperationTimeoutSeconds: TimeInterval = 300.0

    /// Timeout para operaciones de encriptación
    /// - Default: 10 segundos
    public var encryptionTimeoutSeconds: TimeInterval = 10.0

    /// Timeout para operaciones de verificación
    /// - Default: 5 segundos
    public var verificationTimeoutSeconds: TimeInterval = 5.0

    /// Timeout para operaciones de sincronización
    /// - Default: 60 segundos
    public var syncTimeoutSeconds: TimeInterval = 60.0

    /// Timeout para operaciones de ubicación
    /// - Default: 10 segundos
    public var locationTimeoutSeconds: TimeInterval = 10.0

    /// Timeout para operaciones de Nostr
    /// - Default: 15 segundos
    public var nostrTimeoutSeconds: TimeInterval = 15.0

    /// Timeout para operaciones de Tor
    /// - Default: 30 segundos
    public var torTimeoutSeconds: TimeInterval = 30.0

    /// Timeout para operaciones de Geo
    /// - Default: 10 segundos
    public var geoTimeoutSeconds: TimeInterval = 10.0

    /// Timeout para operaciones de Media
    /// - Default: 60 segundos
    public var mediaTimeoutSeconds: TimeInterval = 60.0

    /// Timeout para operaciones de Noise
    /// - Default: 5 segundos
    public var noiseTimeoutSeconds: TimeInterval = 5.0

    /// Timeout para operaciones de Utils
    /// - Default: 10 segundos
    public var utilsTimeoutSeconds: TimeInterval = 10.0

    /// Timeout para operaciones de Reliability
    /// - Default: 30 segundos
    public var reliabilityTimeoutSeconds: TimeInterval = 30.0

    /// Timeout para operaciones de Routing
    /// - Default: 15 segundos
    public var routingTimeoutSeconds: TimeInterval = 15.0

    /// Timeout para operaciones de Sync
    /// - Default: 60 segundos
    public var syncTimeoutSeconds2: TimeInterval = 60.0

    /// Timeout para operaciones de Verification
    /// - Default: 5 segundos
    public var verificationTimeoutSeconds2: TimeInterval = 5.0

    // MARK: - Location / Geo

    /// Precisión de ubicación por defecto
    /// - Default: 10 metros
    public var locationDefaultAccuracy: Double = 10.0

    /// Distancia mínima para actualizaciones de ubicación
    /// - Default: 50 metros
    public var locationMinDistanceFilter: Double = 50.0

    /// Timeout para obtener ubicación
    /// - Default: 30 segundos
    public var locationAcquisitionTimeout: TimeInterval = 30.0

    /// Intervalo máximo entre actualizaciones de ubicación
    /// - Default: 300 segundos (5 minutos)
    public var locationMaxUpdateInterval: TimeInterval = 300.0

    /// Radio de búsqueda de relays geográficos
    /// - Default: 5000 metros (5 km)
    public var geoRelaySearchRadius: Double = 5000.0

    /// Límite de relays geográficos por búsqueda
    /// - Default: 10
    public var geoMaxRelaysPerSearch: Int = 10

    /// Timeout para búsqueda de relays geográficos
    /// - Default: 10 segundos
    public var geoRelaySearchTimeout: TimeInterval = 10.0

    /// Intervalo de actualización de relays geográficos
    /// - Default: 3600 segundos (1 hora)
    public var geoRelayUpdateInterval: TimeInterval = 3600.0

    // MARK: - Nostr

    /// Límite de conexiones Nostr simultáneas
    /// - Default: 10
    public var nostrMaxConnections: Int = 10

    /// Timeout para conexiones Nostr
    /// - Default: 10 segundos
    public var nostrConnectionTimeout: TimeInterval = 10.0

    /// Límite de mensajes Nostr por segundo
    /// - Default: 100
    public var nostrMaxMessagesPerSecond: Int = 100

    /// Límite de tamaño de mensaje Nostr
    /// - Default: 16384 bytes (16 KB)
    public var nostrMaxMessageSize: Int = 16384

    /// Límite de suscripciones Nostr activas
    /// - Default: 50
    public var nostrMaxActiveSubscriptions: Int = 50

    /// Timeout para suscripciones Nostr
    /// - Default: 300 segundos (5 minutos)
    public var nostrSubscriptionTimeout: TimeInterval = 300.0

    /// Intervalo de ping Nostr
    /// - Default: 60 segundos
    public var nostrPingInterval: TimeInterval = 60.0

    /// Límite de relays Nostr por cliente
    /// - Default: 5
    public var nostrMaxRelaysPerClient: Int = 5

    // MARK: - Compression / Encoding

    /// Nivel de compresión por defecto
    /// - Default: 6 (balance entre velocidad y compresión)
    /// - Rango: 0 (sin compresión) - 9 (máxima compresión)
    public var compressionDefaultLevel: Int = 6

    /// Umbral mínimo para compresión
    /// - Default: 1024 bytes
    public var compressionMinSizeThreshold: Int = 1024

    /// Límite máximo de tamaño comprimido (para evitar expansión)
    /// - Default: 1048576 bytes (1 MB)
    public var compressionMaxCompressedSize: Int = 1048576

    /// Timeout para operaciones de compresión
    /// - Default: 5 segundos
    public var compressionTimeout: TimeInterval = 5.0

    /// Buffer size para operaciones de compresión
    /// - Default: 8192 bytes
    public var compressionBufferSize: Int = 8192

    // MARK: - File Transfers

    /// Límite de tamaño de archivo por defecto
    /// - Default: 10485760 bytes (10 MB)
    public var fileTransferMaxSize: Int = 10485760

    /// Límite de transferencias simultáneas
    /// - Default: 3
    public var fileTransferMaxConcurrent: Int = 3

    /// Timeout para transferencias de archivo
    /// - Default: 300 segundos (5 minutos)
    public var fileTransferTimeout: TimeInterval = 300.0

    /// Tamaño de chunk para transferencias
    /// - Default: 65536 bytes (64 KB)
    public var fileTransferChunkSize: Int = 65536

    /// Límite de reintentos para transferencias
    /// - Default: 3
    public var fileTransferMaxRetries: Int = 3

    /// Delay entre reintentos de transferencia
    /// - Default: 2 segundos
    public var fileTransferRetryDelay: TimeInterval = 2.0

    /// Límite de archivos en cola
    /// - Default: 10
    public var fileTransferMaxQueued: Int = 10

    // MARK: - Validation

    /// Método de validación de configuración
    public func validate() throws {
        // BLE validation
        guard bleDefaultFragmentSize >= 64 && bleDefaultFragmentSize <= 512 else {
            throw ValidationError.invalidValue("bleDefaultFragmentSize must be between 64 and 512")
        }
        guard messageTTLDefault >= 1 && messageTTLDefault <= 20 else {
            throw ValidationError.invalidValue("messageTTLDefault must be between 1 and 20")
        }
        guard bleMaxInFlightAssemblies >= 1 && bleMaxInFlightAssemblies <= 1000 else {
            throw ValidationError.invalidValue("bleMaxInFlightAssemblies must be between 1 and 1000")
        }

        // UI validation
        let uiLimits = [uiMaxQueuedMessages, uiMaxQueuedReceivedMessages, uiMaxQueuedRetransmissions,
                       uiMaxQueuedNotifications, uiMaxQueuedFileMessages, uiMaxQueuedLocationMessages,
                       uiMaxQueuedStatusMessages, uiMaxQueuedModerationMessages, uiMaxQueuedAnalyticsMessages,
                       uiMaxQueuedCommunityMessages, uiMaxQueuedIdentityMessages, uiMaxQueuedVerificationMessages,
                       uiMaxQueuedTransportMessages, uiMaxQueuedSyncMessages, uiMaxQueuedStateMessages,
                       uiMaxQueuedTorMessages, uiMaxQueuedNostrMessages, uiMaxQueuedGeoMessages,
                       uiMaxQueuedMediaMessages, uiMaxQueuedNoiseMessages, uiMaxQueuedUtilsMessages,
                       uiMaxQueuedReliabilityMessages, uiMaxQueuedRoutingMessages, uiMaxQueuedSyncMessages2,
                       uiMaxQueuedVerificationMessages2]

        for limit in uiLimits {
            guard limit >= 1 && limit <= 10000 else {
                throw ValidationError.invalidValue("UI queue limits must be between 1 and 10000")
            }
        }

        // Timeout validation
        let timeouts = [networkTimeoutSeconds, fileOperationTimeoutSeconds, encryptionTimeoutSeconds,
                       verificationTimeoutSeconds, syncTimeoutSeconds, locationTimeoutSeconds,
                       nostrTimeoutSeconds, torTimeoutSeconds, geoTimeoutSeconds, mediaTimeoutSeconds,
                       noiseTimeoutSeconds, utilsTimeoutSeconds, reliabilityTimeoutSeconds,
                       routingTimeoutSeconds, syncTimeoutSeconds2, verificationTimeoutSeconds2]

        for timeout in timeouts {
            guard timeout >= 1.0 && timeout <= 3600.0 else {
                throw ValidationError.invalidValue("Timeouts must be between 1 and 3600 seconds")
            }
        }

        // Location validation
        guard locationDefaultAccuracy >= 1.0 && locationDefaultAccuracy <= 1000.0 else {
            throw ValidationError.invalidValue("locationDefaultAccuracy must be between 1 and 1000 meters")
        }
        guard locationMinDistanceFilter >= 1.0 && locationMinDistanceFilter <= 10000.0 else {
            throw ValidationError.invalidValue("locationMinDistanceFilter must be between 1 and 10000 meters")
        }

        // Nostr validation
        guard nostrMaxConnections >= 1 && nostrMaxConnections <= 100 else {
            throw ValidationError.invalidValue("nostrMaxConnections must be between 1 and 100")
        }
        guard nostrMaxMessagesPerSecond >= 1 && nostrMaxMessagesPerSecond <= 1000 else {
            throw ValidationError.invalidValue("nostrMaxMessagesPerSecond must be between 1 and 1000")
        }

        // Compression validation
        guard compressionDefaultLevel >= 0 && compressionDefaultLevel <= 9 else {
            throw ValidationError.invalidValue("compressionDefaultLevel must be between 0 and 9")
        }
        guard compressionMinSizeThreshold >= 100 && compressionMinSizeThreshold <= 1000000 else {
            throw ValidationError.invalidValue("compressionMinSizeThreshold must be between 100 and 1000000 bytes")
        }

        // File transfer validation
        guard fileTransferMaxSize >= 1024 && fileTransferMaxSize <= 1073741824 else {
            throw ValidationError.invalidValue("fileTransferMaxSize must be between 1024 and 1073741824 bytes")
        }
        guard fileTransferMaxConcurrent >= 1 && fileTransferMaxConcurrent <= 10 else {
            throw ValidationError.invalidValue("fileTransferMaxConcurrent must be between 1 and 10")
        }
    }

    /// Errores de validación
    public enum ValidationError: Error {
        case invalidValue(String)
    }
}
