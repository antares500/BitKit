import Foundation

/// Centralized knobs for transport- and UI-related limits.
/// Keep values aligned with existing behavior when replacing magic numbers.
/// Todos los valores son configurables en tiempo de ejecución.
public class TransportConfig {
    /// Singleton compartido con configuración por defecto
    public static let shared = TransportConfig()

    // Inicializador privado para singleton
    private init() {}

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

    /// Intervalo mínimo para anuncios BLE (segundos)
    /// - Default: 5.0 segundos
    public var bleAnnounceMinInterval: TimeInterval = 5.0

    /// Máximo número de enlaces centrales BLE
    /// - Default: 10
    public var bleMaxCentralLinks: Int = 10

    /// Intervalo de límite de tasa para conexiones BLE (segundos)
    /// - Default: 1.0 segundos
    public var bleConnectRateLimitInterval: TimeInterval = 1.0

    /// Ventana para paquetes recientes BLE (segundos)
    /// - Default: 10.0 segundos
    public var bleRecentPacketWindowSeconds: TimeInterval = 10.0

    /// Máximo conteo de paquetes recientes BLE
    /// - Default: 100
    public var bleRecentPacketWindowMaxCount: Int = 100

    /// Intervalo para anuncios BLE (segundos)
    /// - Default: 30.0 segundos
    public var bleAnnounceIntervalSeconds: TimeInterval = 30.0

    /// Base de anuncios conectados en redes densas (segundos)
    /// - Default: 60.0 segundos
    public var bleConnectedAnnounceBaseSecondsDense: TimeInterval = 60.0

    /// Base de anuncios conectados en redes dispersas (segundos)
    /// - Default: 30.0 segundos
    public var bleConnectedAnnounceBaseSecondsSparse: TimeInterval = 30.0

    /// Jitter de anuncios conectados en redes densas (segundos)
    /// - Default: 10.0 segundos
    public var bleConnectedAnnounceJitterDense: TimeInterval = 10.0

    /// Jitter de anuncios conectados en redes dispersas (segundos)
    /// - Default: 5.0 segundos
    public var bleConnectedAnnounceJitterSparse: TimeInterval = 5.0

    /// Retención de alcance verificado BLE (segundos)
    /// - Default: 3600.0 segundos
    public var bleReachabilityRetentionVerifiedSeconds: TimeInterval = 3600.0

    /// Retención de alcance no verificado BLE (segundos)
    /// - Default: 1800.0 segundos
    public var bleReachabilityRetentionUnverifiedSeconds: TimeInterval = 1800.0

    /// Timeout de inactividad de peer BLE (segundos)
    /// - Default: 300.0 segundos
    public var blePeerInactivityTimeoutSeconds: TimeInterval = 300.0

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

    /// BLE operational delays
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

    /// Umbral RSSI para enlaces débiles
    /// - Default: -70 dBm
    public var bleWeakLinkRSSICutoff: Int = -70

    /// Tiempo de enfriamiento para reenlaces débiles (segundos)
    /// - Default: 30 segundos
    public var bleWeakLinkCooldownSeconds: TimeInterval = 30.0

    /// Factor de retroceso para límite de tasa de suscripción
    /// - Default: 2.0
    public var bleSubscriptionRateLimitBackoffFactor: Double = 2.0

    /// Máximo retroceso para límite de tasa de suscripción (segundos)
    /// - Default: 300 segundos
    public var bleSubscriptionRateLimitMaxBackoffSeconds: TimeInterval = 300.0

    /// Máximo número de intentos para límite de tasa de suscripción
    /// - Default: 10
    public var bleSubscriptionRateLimitMaxAttempts: Int = 10

    /// Capacidad máxima del buffer de escritura pendiente (bytes)
    /// - Default: 1048576 (1MB)
    public var blePendingWriteBufferCapBytes: Int = 1048576

    /// Tiempo máximo esperado para escritura (ms)
    /// - Default: 5000 ms
    public var bleExpectedWriteMaxMs: Int = 5000

    /// Tiempo esperado por fragmento de escritura (ms)
    /// - Default: 50 ms
    public var bleExpectedWritePerFragmentMs: Int = 50

    /// Espaciado entre fragmentos dirigidos (ms)
    /// - Default: 25 ms
    public var bleFragmentSpacingDirectedMs: Int = 25

    /// Espaciado entre fragmentos (ms)
    /// - Default: 8 ms
    public var bleFragmentSpacingMs: Int = 8

    /// Umbral RSSI dinámico por defecto
    /// - Default: -75 dBm
    public var bleDynamicRSSIThresholdDefault: Int = -75

    /// Duración activa del ciclo de trabajo (segundos)
    /// - Default: 10.0 segundos
    public var bleDutyOnDuration: TimeInterval = 10.0

    /// Duración inactiva del ciclo de trabajo (segundos)
    /// - Default: 20.0 segundos
    public var bleDutyOffDuration: TimeInterval = 20.0

    /// Intervalo de mantenimiento BLE (segundos)
    /// - Default: 30.0 segundos
    public var bleMaintenanceInterval: TimeInterval = 30.0

    /// Tolerancia de mantenimiento BLE (segundos)
    /// - Default: 5 segundos
    public var bleMaintenanceLeewaySeconds: Int = 5

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

    /// Límite de mensajes en cola de Utils
    /// - Default: 50
    public var uiMaxQueuedUtilsMessages: Int = 50

    /// Límite de mensajes en cola de Reliability
    /// - Default: 100
    public var uiMaxQueuedReliabilityMessages: Int = 100

    /// Límite de mensajes en cola de Routing
    /// - Default: 100
    public var uiMaxQueuedRoutingMessages: Int = 100

    /// Máximo número de candidatos de conexión BLE
    /// - Default: 50
    public var bleConnectionCandidatesMax: Int = 50

    /// Tiempo de vida de fragmentos BLE (segundos)
    /// - Default: 30.0 segundos
    public var bleFragmentLifetimeSeconds: TimeInterval = 30.0

    /// Ventana de retroceso para timeout de conexión BLE (segundos)
    /// - Default: 300.0 segundos
    public var bleConnectTimeoutBackoffWindowSeconds: TimeInterval = 300.0

    /// Tiempo de vida de registros de entrada BLE (segundos)
    /// - Default: 60.0 segundos
    public var bleIngressRecordLifetimeSeconds: TimeInterval = 60.0

    /// Edad máxima para deduplicación de mensajes (segundos)
    /// - Default: 300.0 segundos
    public var messageDedupMaxAgeSeconds: TimeInterval = 300.0

    /// Ventana para forzar escaneo por tráfico reciente BLE (segundos)
    /// - Default: 10.0 segundos
    public var bleRecentTrafficForceScanSeconds: TimeInterval = 10.0

    /// Duración activa del ciclo de trabajo en redes densas (segundos)
    /// - Default: 5.0 segundos
    public var bleDutyOnDurationDense: TimeInterval = 5.0

    /// Duración inactiva del ciclo de trabajo en redes densas (segundos)
    /// - Default: 10.0 segundos
    public var bleDutyOffDurationDense: TimeInterval = 10.0

    /// Umbral para relajar aislamiento BLE (segundos)
    /// - Default: 60.0 segundos
    public var bleIsolationRelaxThresholdSeconds: TimeInterval = 60.0

    /// Umbral RSSI para peers aislados relajado
    /// - Default: -80 dBm
    public var bleRSSIIsolatedRelaxed: Int = -80

    /// Umbral RSSI base para peers aislados
    /// - Default: -70 dBm
    public var bleRSSIIsolatedBase: Int = -70

    /// Umbral RSSI para peers conectados
    /// - Default: -65 dBm
    public var bleRSSIConnectedThreshold: Int = -65

    /// Ventana para timeouts recientes BLE (segundos)
    /// - Default: 300.0 segundos
    public var bleRecentTimeoutWindowSeconds: TimeInterval = 300.0

    /// Umbral de conteo de timeouts recientes BLE
    /// - Default: 5
    public var bleRecentTimeoutCountThreshold: Int = 5

    /// Umbral RSSI alto para timeouts BLE
    /// - Default: -60 dBm
    public var bleRSSIHighTimeoutThreshold: Int = -60

    /// Delay corto para escritura en thread BLE (segundos)
    /// - Default: 0.01 segundos
    public var bleThreadSleepWriteShortDelaySeconds: TimeInterval = 0.01

    /// Capacidad máxima de notificaciones pendientes BLE
    /// - Default: 100
    public var blePendingNotificationsCapCount: Int = 100

    /// Intervalo mínimo para forzar anuncio BLE (segundos)
    /// - Default: 5.0 segundos
    public var bleForceAnnounceMinIntervalSeconds: TimeInterval = 5.0

    /// Máximo número de reintentos para notificaciones BLE
    /// - Default: 3
    public var bleNotificationRetryMaxAttempts: Int = 3

    /// Delay de reintento para notificaciones BLE (ms)
    /// - Default: 1000 ms
    public var bleNotificationRetryDelayMs: Int = 1000

    // MARK: - Timers / Timeouts

    /// Timeout para operaciones de red
    /// - Default: 30 segundos
    public var networkTimeoutSeconds: TimeInterval = 30.0

    /// Timeout para operaciones de archivo
    /// - Default: 300 segundos (5 minutos)
    public var fileOperationTimeoutSeconds: TimeInterval = 300.0

    // MARK: - Sync Configuration

    /// Timeout para operaciones de sincronización
    /// - Default: 60 segundos
    public var syncTimeoutSeconds: TimeInterval = 60.0

    /// Intervalo de sincronización por defecto
    /// - Default: 300 segundos (5 minutos)
    public var syncDefaultIntervalSeconds: TimeInterval = 300.0

    /// Capacidad de visto en sincronización
    /// - Default: 10000
    public var syncSeenCapacity: Int = 10000

    /// Máximo bytes para GCS en sincronización
    /// - Default: 1048576 (1MB)
    public var syncGCSMaxBytes: Int = 1048576

    /// FPR objetivo para GCS en sincronización
    /// - Default: 0.001
    public var syncGCSTargetFpr: Double = 0.001

    /// Edad máxima de mensaje en sincronización (segundos)
    /// - Default: 86400.0 (1 día)
    public var syncMaxMessageAgeSeconds: TimeInterval = 86400.0

    /// Intervalo de mantenimiento en sincronización (segundos)
    /// - Default: 3600.0 (1 hora)
    public var syncMaintenanceIntervalSeconds: TimeInterval = 3600.0

    /// Intervalo de limpieza de peers obsoletos en sincronización (segundos)
    /// - Default: 7200.0 (2 horas)
    public var syncStalePeerCleanupIntervalSeconds: TimeInterval = 7200.0

    /// Timeout de peers obsoletos en sincronización (segundos)
    /// - Default: 259200.0 (3 días)
    public var syncStalePeerTimeoutSeconds: TimeInterval = 259200.0

    /// Capacidad de fragmentos en sincronización
    /// - Default: 100
    public var syncFragmentCapacity: Int = 100

    /// Capacidad de transferencias de archivos en sincronización
    /// - Default: 10
    public var syncFileTransferCapacity: Int = 10

    /// Intervalo de sincronización de fragmentos (segundos)
    /// - Default: 60.0
    public var syncFragmentIntervalSeconds: TimeInterval = 60.0

    /// Intervalo de sincronización de transferencias de archivos (segundos)
    /// - Default: 300.0
    public var syncFileTransferIntervalSeconds: TimeInterval = 300.0

    /// Intervalo de sincronización de mensajes (segundos)
    /// - Default: 30.0
    public var syncMessageIntervalSeconds: TimeInterval = 30.0

    // MARK: - Location / Geo

    /// Timeout para operaciones de geolocalización
    /// - Default: 10 segundos
    public var locationTimeoutSeconds: TimeInterval = 10.0

    /// Precisión por defecto para geolocalización
    /// - Default: 100 metros
    public var locationDefaultAccuracy: Double = 100.0

    /// Intervalo de refresco en vivo de ubicación (segundos)
    /// - Default: 60.0 segundos
    public var locationLiveRefreshInterval: TimeInterval = 60.0

    /// Filtro de distancia para ubicación normal (metros)
    /// - Default: 100.0 metros
    public var locationDistanceFilterMeters: Double = 100.0

    /// Filtro de distancia para ubicación en vivo (metros)
    /// - Default: 10.0 metros
    public var locationDistanceFilterLiveMeters: Double = 10.0

    // MARK: - Nostr

    /// Longitud del prefijo de clave de conversación Nostr
    /// - Default: 16
    public var nostrConvKeyPrefixLength: Int = 16

    /// Longitud de visualización corta de clave Nostr
    /// - Default: 8
    public var nostrShortKeyDisplayLength: Int = 8

    /// Timeout inicial para relay Nostr (segundos)
    /// - Default: 5.0 segundos
    public var nostrRelayInitialBackoffSeconds: TimeInterval = 5.0

    /// Timeout máximo para relay Nostr (segundos)
    /// - Default: 300.0 segundos
    public var nostrRelayMaxBackoffSeconds: TimeInterval = 300.0

    /// Multiplicador de retroceso para relay Nostr
    /// - Default: 2.0
    public var nostrRelayBackoffMultiplier: Double = 2.0

    /// Máximo número de reintentos para relay Nostr
    /// - Default: 10
    public var nostrRelayMaxReconnectAttempts: Int = 10

    /// Timeout para conexiones Nostr
    /// - Default: 10 segundos
    public var nostrConnectionTimeoutSeconds: TimeInterval = 10.0

    // MARK: - Geo Relay

    /// Intervalo de fetch para geo relay (segundos)
    /// - Default: 3600.0 segundos (1 hora)
    public var geoRelayFetchIntervalSeconds: TimeInterval = 3600.0

    /// Segundos iniciales de retry para geo relay
    /// - Default: 60.0 segundos
    public var geoRelayRetryInitialSeconds: TimeInterval = 60.0

    /// Segundos máximos de retry para geo relay
    /// - Default: 3600.0 segundos (1 hora)
    public var geoRelayRetryMaxSeconds: TimeInterval = 3600.0

    /// Intervalo de check de refresh para geo relay (segundos)
    /// - Default: 300.0 segundos (5 minutos)
    public var geoRelayRefreshCheckIntervalSeconds: TimeInterval = 300.0

    // MARK: - File Transfers

    /// Timeout para transferencias de archivos
    /// - Default: 600 segundos (10 minutos)
    public var fileTransferTimeoutSeconds: TimeInterval = 600.0

    /// Tamaño máximo de fragmento para transferencias de archivos
    /// - Default: 65536 bytes (64KB)
    public var fileTransferMaxFragmentSize: Int = 65536

    // MARK: - Validation

    /// Valida que todos los valores de configuración sean razonables
    public func validate() throws {
        // BLE validation
        guard bleDefaultFragmentSize >= 128 && bleDefaultFragmentSize <= 512 else {
            throw ValidationError.invalidValue("bleDefaultFragmentSize must be between 128 and 512")
        }

        guard messageTTLDefault >= 1 && messageTTLDefault <= 20 else {
            throw ValidationError.invalidValue("messageTTLDefault must be between 1 and 20")
        }

        // Nostr validation
        guard nostrConvKeyPrefixLength >= 8 && nostrConvKeyPrefixLength <= 32 else {
            throw ValidationError.invalidValue("nostrConvKeyPrefixLength must be between 8 and 32")
        }

        guard nostrShortKeyDisplayLength >= 4 && nostrShortKeyDisplayLength <= 16 else {
            throw ValidationError.invalidValue("nostrShortKeyDisplayLength must be between 4 and 16")
        }
    }

    /// Errores de validación
    public enum ValidationError: Error {
        case invalidValue(String)
    }
}

// MARK: - Notifications

extension Notification.Name {
    public static let TorDidBecomeReady = Notification.Name("TorDidBecomeReady")
}