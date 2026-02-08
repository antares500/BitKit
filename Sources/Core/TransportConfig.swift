import Foundation

/// Centralized knobs for transport- and UI-related limits.
/// Keep values aligned with existing behavior when replacing magic numbers.
public enum TransportConfig {
    // BLE / Protocol
    public static let bleDefaultFragmentSize: Int = 469            // ~512 MTU minus protocol overhead
    public static let messageTTLDefault: UInt8 = 7                 // Default TTL for mesh flooding
    public static let bleMaxInFlightAssemblies: Int = 128          // Cap concurrent fragment assemblies
    public static let bleHighDegreeThreshold: Int = 6              // For adaptive TTL/probabilistic relays
    public static let bleMaxConcurrentTransfers: Int = 2           // Limit simultaneous large media sends
    public static let bleFragmentRelayMinDelayMs: Int = 8          // Faster forwarding for media fragments
    public static let bleFragmentRelayMaxDelayMs: Int = 25         // Upper jitter bound for fragment relays
    public static let bleFragmentRelayTtlCap: UInt8 = 5            // Clamp fragment TTL to contain floods

    // UI / Storage Caps
    public static let privateChatCap: Int = 1337
    public static let meshTimelineCap: Int = 1337
    public static let geoTimelineCap: Int = 1337
    public static let contentLRUCap: Int = 2000

    // Timers
    public static let networkResetGraceSeconds: TimeInterval = 600 // 10 minutes
    public static let networkNotificationCooldownSeconds: TimeInterval = 300 // 5 minutes
    public static let basePublicFlushInterval: TimeInterval = 0.08  // ~12.5 fps batching

    // BLE duty/announce/connect
    public static let bleConnectRateLimitInterval: TimeInterval = 0.5
    public static let bleMaxCentralLinks: Int = 6
    public static let bleDutyOnDuration: TimeInterval = 5.0
    public static let bleDutyOffDuration: TimeInterval = 10.0
    public static let bleAnnounceMinInterval: TimeInterval = 1.0

    // BLE discovery/quality thresholds
    public static let bleDynamicRSSIThresholdDefault: Int = -90
    public static let bleConnectionCandidatesMax: Int = 100
    public static let blePendingWriteBufferCapBytes: Int = 1_000_000
    public static let bleNotificationAssemblerHardCapBytes: Int = 8 * 1024 * 1024
    public static let bleAssemblerStallResetMs: Int = 250
    public static let blePendingNotificationsCapCount: Int = 128
    public static let bleNotificationRetryDelayMs: Int = 25
    public static let bleNotificationRetryMaxAttempts: Int = 80

    // Nostr
    public static let nostrReadAckInterval: TimeInterval = 0.35 // ~3 per second

    // UI thresholds
    public static let uiLateInsertThreshold: TimeInterval = 15.0
    public static let uiLateInsertThresholdGeo: TimeInterval = 0.0
    public static let uiProcessedNostrEventsCap: Int = 2000
    public static let uiChannelInactivityThresholdSeconds: TimeInterval = 9 * 60
    
    // UI rate limiters (token buckets)
    public static let uiSenderRateBucketCapacity: Double = 5
    public static let uiSenderRateBucketRefillPerSec: Double = 1.0
    public static let uiContentRateBucketCapacity: Double = 3
    public static let uiContentRateBucketRefillPerSec: Double = 0.5

    // UI sleeps/delays
    public static let uiStartupInitialDelaySeconds: TimeInterval = 1.0
    public static let uiStartupShortSleepNs: UInt64 = 200_000_000
    public static let uiStartupPhaseDurationSeconds: TimeInterval = 2.0
    public static let uiAsyncShortSleepNs: UInt64 = 100_000_000
    public static let uiAsyncMediumSleepNs: UInt64 = 500_000_000
    public static let uiReadReceiptRetryShortSeconds: TimeInterval = 0.1
    public static let uiReadReceiptRetryLongSeconds: TimeInterval = 0.5
    public static let uiBatchDispatchStaggerSeconds: TimeInterval = 0.15
    public static let uiScrollThrottleSeconds: TimeInterval = 0.5
    public static let uiAnimationShortSeconds: TimeInterval = 0.15
    public static let uiAnimationMediumSeconds: TimeInterval = 0.2
    public static let uiAnimationSidebarSeconds: TimeInterval = 0.25
    public static let uiRecentCutoffFiveMinutesSeconds: TimeInterval = 5 * 60
    public static let uiMeshEmptyConfirmationSeconds: TimeInterval = 30.0

    // BLE maintenance & thresholds
    public static let bleMaintenanceInterval: TimeInterval = 5.0
    public static let bleMaintenanceLeewaySeconds: Int = 1
    public static let bleIsolationRelaxThresholdSeconds: TimeInterval = 60
    public static let bleRecentTimeoutWindowSeconds: TimeInterval = 60
    public static let bleRecentTimeoutCountThreshold: Int = 3
    public static let bleRSSIIsolatedBase: Int = -90
    public static let bleRSSIIsolatedRelaxed: Int = -92
    public static let bleRSSIConnectedThreshold: Int = -85
    public static let bleRSSIHighTimeoutThreshold: Int = -80
    // How long without seeing traffic before we sanity-check the direct link
    // Lowered to make connected→reachable icon changes react faster when walking out of range
    public static let blePeerInactivityTimeoutSeconds: TimeInterval = 8.0
    // How long to retain a peer as "reachable" (not directly connected) since lastSeen
    public static let bleReachabilityRetentionVerifiedSeconds: TimeInterval = 21.0    // 21s for verified/favorites
    public static let bleReachabilityRetentionUnverifiedSeconds: TimeInterval = 21.0  // 21s for unknown/unverified
    public static let bleFragmentLifetimeSeconds: TimeInterval = 30.0
    public static let bleIngressRecordLifetimeSeconds: TimeInterval = 3.0
    public static let bleConnectTimeoutBackoffWindowSeconds: TimeInterval = 120.0
    public static let bleRecentPacketWindowSeconds: TimeInterval = 30.0
    public static let bleRecentPacketWindowMaxCount: Int = 100
    // Keep scanning fully ON when we saw traffic very recently
    public static let bleRecentTrafficForceScanSeconds: TimeInterval = 10.0
    public static let bleThreadSleepWriteShortDelaySeconds: TimeInterval = 0.05
    public static let bleExpectedWritePerFragmentMs: Int = 20
    public static let bleExpectedWriteMaxMs: Int = 5000
    // Fragment pacing: Conservative spacing to prevent BLE buffer overflow
    // Aggressive pacing causes packet loss; needs 25-30ms between fragments for reliable delivery
    public static let bleFragmentSpacingMs: Int = 30
    public static let bleFragmentSpacingDirectedMs: Int = 25
    public static let bleAnnounceIntervalSeconds: TimeInterval = 4.0
    public static let bleDutyOnDurationDense: TimeInterval = 3.0
    public static let bleDutyOffDurationDense: TimeInterval = 15.0
    public static let bleConnectedAnnounceBaseSecondsDense: TimeInterval = 30.0
    public static let bleConnectedAnnounceBaseSecondsSparse: TimeInterval = 15.0
    public static let bleConnectedAnnounceJitterDense: TimeInterval = 8.0
    public static let bleConnectedAnnounceJitterSparse: TimeInterval = 4.0

    // Location
    public static let locationDistanceFilterMeters: Double = 1000
    // Live (channel sheet open) distance threshold for meaningful updates
    public static let locationDistanceFilterLiveMeters: Double = 10.0
    public static let locationLiveRefreshInterval: TimeInterval = 5.0

    // Notifications (geohash)
    public static let uiGeoNotifyCooldownSeconds: TimeInterval = 60.0
    public static let uiGeoNotifySnippetMaxLen: Int = 80

    // Nostr geohash
    public static let nostrGeohashInitialLookbackSeconds: TimeInterval = 3600
    public static let nostrGeohashInitialLimit: Int = 200
    public static let nostrGeoRelayCount: Int = 5
    public static let nostrGeohashSampleLookbackSeconds: TimeInterval = 300
    public static let nostrGeohashSampleLimit: Int = 100
    public static let nostrDMSubscribeLookbackSeconds: TimeInterval = 86400

    // Nostr helpers
    public static let nostrShortKeyDisplayLength: Int = 8
    public static let nostrConvKeyPrefixLength: Int = 16

    // Compression
    public static let compressionThresholdBytes: Int = 100

    // Message deduplication
    public static let messageDedupMaxAgeSeconds: TimeInterval = 300
    public static let messageDedupMaxCount: Int = 1000

    // Verification QR
    public static let verificationQRMaxAgeSeconds: TimeInterval = 5 * 60

    // Nostr relay backoff
    public static let nostrRelayInitialBackoffSeconds: TimeInterval = 1.0
    public static let nostrRelayMaxBackoffSeconds: TimeInterval = 300.0
    public static let nostrRelayBackoffMultiplier: Double = 2.0
    public static let nostrRelayMaxReconnectAttempts: Int = 10
    public static let nostrRelayDefaultFetchLimit: Int = 100

    // Geo relay directory
    public static let geoRelayFetchIntervalSeconds: TimeInterval = 60 * 60 * 24
    public static let geoRelayRefreshCheckIntervalSeconds: TimeInterval = 60 * 60
    public static let geoRelayRetryInitialSeconds: TimeInterval = 60
    public static let geoRelayRetryMaxSeconds: TimeInterval = 60 * 60

    // BLE operational delays
    public static let bleInitialAnnounceDelaySeconds: TimeInterval = 0.6
    public static let bleConnectTimeoutSeconds: TimeInterval = 8.0
    public static let bleRestartScanDelaySeconds: TimeInterval = 0.1
    public static let blePostSubscribeAnnounceDelaySeconds: TimeInterval = 0.05
    public static let blePostAnnounceDelaySeconds: TimeInterval = 0.4
    public static let bleForceAnnounceMinIntervalSeconds: TimeInterval = 0.15

    // BCH-01-004: Rate-limiting for subscription-triggered announces
    // Prevents rapid enumeration attacks by rate-limiting announce responses
    public static let bleSubscriptionRateLimitMinSeconds: TimeInterval = 2.0       // Minimum interval between announces per central
    public static let bleSubscriptionRateLimitBackoffFactor: Double = 2.0          // Exponential backoff multiplier
    public static let bleSubscriptionRateLimitMaxBackoffSeconds: TimeInterval = 30.0  // Maximum backoff period
    public static let bleSubscriptionRateLimitWindowSeconds: TimeInterval = 60.0   // Window for tracking subscription attempts
    public static let bleSubscriptionRateLimitMaxAttempts: Int = 5                 // Max attempts before extended cooldown

    // Store-and-forward for directed packets at relays
    public static let bleDirectedSpoolWindowSeconds: TimeInterval = 15.0

    // Log/UI debounce windows
    // Shorter debounce so UI reacts faster while still suppressing duplicate callbacks
    public static let bleDisconnectNotifyDebounceSeconds: TimeInterval = 0.9
    public static let bleReconnectLogDebounceSeconds: TimeInterval = 2.0

    // Weak-link cooldown after connection timeouts
    public static let bleWeakLinkCooldownSeconds: TimeInterval = 30.0
    public static let bleWeakLinkRSSICutoff: Int = -90

    // Content hashing / formatting
    public static let contentKeyPrefixLength: Int = 256
    public static let uiLongMessageLengthThreshold: Int = 2000
    public static let uiVeryLongTokenThreshold: Int = 512
    public static let uiLongMessageLineLimit: Int = 30
    public static let uiFingerprintSampleCount: Int = 3
    
    // UI swipe/gesture thresholds
    public static let uiBackSwipeTranslationLarge: CGFloat = 50
    public static let uiBackSwipeTranslationSmall: CGFloat = 30
    public static let uiBackSwipeVelocityThreshold: CGFloat = 300
    
    // UI color tuning
    public static let uiColorHueAvoidanceDelta: Double = 0.05
    public static let uiColorHueOffset: Double = 0.12
    // Peer list palette
    public static let uiPeerPaletteSlots: Int = 36
    public static let uiPeerPaletteRingBrightnessDeltaLight: Double = 0.07
    public static let uiPeerPaletteRingBrightnessDeltaDark: Double = -0.07

    // UI windowing (infinite scroll)
    public static let uiWindowInitialCountPublic: Int = 300
    public static let uiWindowInitialCountPrivate: Int = 300
    public static let uiWindowStepCount: Int = 200

    // Share extension
    public static let uiShareExtensionDismissDelaySeconds: TimeInterval = 2.0
    public static let uiShareAcceptWindowSeconds: TimeInterval = 30.0
    public static let uiMigrationCutoffSeconds: TimeInterval = 24 * 60 * 60

    // Gossip Sync Configuration
    public static let syncSeenCapacity: Int = 1000
    public static let syncGCSMaxBytes: Int = 400
    public static let syncGCSTargetFpr: Double = 0.01
    public static let syncMaxMessageAgeSeconds: TimeInterval = 900
    public static let syncMaintenanceIntervalSeconds: TimeInterval = 30.0
    public static let syncStalePeerCleanupIntervalSeconds: TimeInterval = 60.0
    public static let syncStalePeerTimeoutSeconds: TimeInterval = 60.0
    public static let syncFragmentCapacity: Int = 600
    public static let syncFileTransferCapacity: Int = 200
    public static let syncFragmentIntervalSeconds: TimeInterval = 30.0
    public static let syncFileTransferIntervalSeconds: TimeInterval = 60.0
    public static let syncMessageIntervalSeconds: TimeInterval = 15.0
}