//
//  RelayController.swift
//  bitchatKit
//
//  Created by Assistant
//

import Foundation

// RelayDecision encapsulates a single relay scheduling choice.
public struct RelayDecision {
    public let shouldRelay: Bool
    public let newTTL: UInt8
    public let delayMs: Int
}

// RelayController centralizes flood control policy for relays.
public struct RelayController {
    public static func decide(ttl: UInt8,
                       senderIsSelf: Bool,
                       isEncrypted: Bool,
                       isDirectedEncrypted: Bool,
                       isFragment: Bool,
                       isDirectedFragment: Bool,
                       isHandshake: Bool,
                       isAnnounce: Bool,
                       degree: Int,
                       highDegreeThreshold: Int = 10) -> RelayDecision {
        let ttlCap = min(ttl, TransportConfig.shared.messageTTLDefault)

        // Suppress obvious non-relays
        if ttlCap <= 1 || senderIsSelf {
            return RelayDecision(shouldRelay: false, newTTL: ttlCap, delayMs: 0)
        }

        // For session-critical or directed traffic, be deterministic and reliable
        if isHandshake || isDirectedFragment || isDirectedEncrypted {
            // Always relay with no TTL cap for these types
            let newTTL = ttlCap &- 1
            // Slight jitter to desynchronize without adding too much latency
            // Tighter for faster multi-hop handshakes and directed DMs
            let delayRange: ClosedRange<Int> = isHandshake ? 10...35 : 20...60
            let delayMs = Int.random(in: delayRange)
            return RelayDecision(shouldRelay: true, newTTL: newTTL, delayMs: delayMs)
        }

        if isFragment {
            let ttlLimit = min(ttlCap, TransportConfig.shared.bleFragmentRelayTtlCap)
            guard ttlLimit > 1 else {
                return RelayDecision(shouldRelay: false, newTTL: ttlLimit, delayMs: 0)
            }
            let newTTL = ttlLimit &- 1
            let delayMs = Int.random(in: TransportConfig.shared.bleFragmentRelayMinDelayMs...TransportConfig.shared.bleFragmentRelayMaxDelayMs)
            return RelayDecision(shouldRelay: true, newTTL: newTTL, delayMs: delayMs)
        }

        // TTL clamping for broadcast
        // - Dense graphs: keep lower but still allow multi-hop bridging
        // - Announces get a bit more headroom
        let ttlLimit: UInt8 = {
            if degree >= highDegreeThreshold {
                return max(UInt8(2), min(ttlCap, UInt8(5)))
            }
            let preferred = UInt8(isAnnounce ? 7 : 6)
            return max(UInt8(2), min(ttlCap, preferred))
        }()
        let newTTL = ttlLimit &- 1

        // Wider jitter window to allow duplicate suppression to win more often
        // For sparse graphs (<=2), relay quickly to avoid cancellation races
        let delayMs: Int
        switch degree {
        case 0...2: delayMs = Int.random(in: 10...40)
        case 3...5: delayMs = Int.random(in: 60...150)
        case 6...9: delayMs = Int.random(in: 80...180)
        default:    delayMs = Int.random(in: 100...220)
        }
        return RelayDecision(shouldRelay: true, newTTL: newTTL, delayMs: delayMs)
    }
}