import Foundation

/// Centralized knobs for transport- and UI-related limits.
/// Keep values aligned with existing behavior when replacing magic numbers.
/// Todos los valores son configurables en tiempo de ejecución.
public class TransportConfiguration {
    /// Singleton compartido con configuración por defecto
    public static var shared = TransportConfiguration()

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
    public var blePostAnnounceDelaySeconds: TimeInterval = 0.4
    public var bleForceAnnounceMinIntervalSeconds: TimeInterval = 0.15

    // BCH-01-004: Rate-limiting for subscription-triggered announces
    // Prevents rapid enumeration attacks by rate-limiting announce responses
    public var bleSubscriptionRateLimitMinSeconds: TimeInterval = 2.0       // Minimum interval between announces per central
    public var bleSubscriptionRateLimitBackoffFactor: Double = 2.0          // Exponential backoff multiplier
    public var bleSubscriptionRateLimitMaxBackoffSeconds: TimeInterval = 30.0  // Maximum backoff period
    public var bleSubscriptionRateLimitWindowSeconds: TimeInterval = 60.0   // Window for tracking subscription attempts
    public var bleSubscriptionRateLimitMaxAttempts: Int = 5                 // Max attempts before extended cooldown

    // Store-and-forward for directed packets at relays
    public var bleDirectedSpoolWindowSeconds: TimeInterval = 15.0

    // Log/UI debounce windows
    // Shorter debounce so UI reacts faster while still suppressing duplicate callbacks
    public var bleDisconnectNotifyDebounceSeconds: TimeInterval = 0.9
    public var bleReconnectLogDebounceSeconds: TimeInterval = 2.0

    // Weak-link cooldown after connection timeouts
    public var bleWeakLinkCooldownSeconds: TimeInterval = 30.0
    public var bleWeakLinkRSSICutoff: Int = -90

    // Gossip Sync Configuration
    public var syncSeenCapacity: Int = 1000
    public var syncGCSMaxBytes: Int = 400
    public var syncGCSTargetFpr: Double = 0.01
    public var syncMaxMessageAgeSeconds: TimeInterval = 900
    public var syncMaintenanceIntervalSeconds: TimeInterval = 30.0
    public var syncStalePeerCleanupIntervalSeconds: TimeInterval = 60.0
    public var syncStalePeerTimeoutSeconds: TimeInterval = 60.0
    public var syncFragmentCapacity: Int = 600
    public var syncFileTransferCapacity: Int = 200
    public var syncFragmentIntervalSeconds: TimeInterval = 30.0
    public var syncFileTransferIntervalSeconds: TimeInterval = 60.0
    public var syncMessageIntervalSeconds: TimeInterval = 15.0
}
