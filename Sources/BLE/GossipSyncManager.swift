//
// GossipSyncManager.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import BitCore
import BitLogger

/// Delegate for GossipSyncManager
public protocol GossipSyncManagerDelegate: AnyObject {
    func sendPacket(_ packet: BitPacket)
    func sendPacket(to peerID: PeerID, packet: BitPacket)
    func signPacketForBroadcast(_ packet: BitPacket) -> BitPacket
    func verifyPacketSignature(_ packet: BitPacket) -> Bool
    func getConnectedPeers() -> [PeerID]
}

/// Manages gossip-based synchronization
public class GossipSyncManager {
    private struct PacketStore {
        private(set) var packets: [String: BitPacket] = [:]
        private(set) var order: [String] = []

        mutating func insert(idHex: String, packet: BitPacket, capacity: Int) {
            guard capacity > 0 else { return }
            if packets[idHex] != nil {
                packets[idHex] = packet
                return
            }
            packets[idHex] = packet
            order.append(idHex)
            while order.count > capacity {
                let victim = order.removeFirst()
                packets.removeValue(forKey: victim)
            }
        }

        func allPackets(isFresh: (BitPacket) -> Bool) -> [BitPacket] {
            order.compactMap { key in
                guard let packet = packets[key], isFresh(packet) else { return nil }
                return packet
            }
        }

        mutating func remove(where shouldRemove: (BitPacket) -> Bool) {
            var nextOrder: [String] = []
            for key in order {
                guard let packet = packets[key] else { continue }
                if shouldRemove(packet) {
                    packets.removeValue(forKey: key)
                } else {
                    nextOrder.append(key)
                }
            }
            order = nextOrder
        }

        mutating func removeExpired(isFresh: (BitPacket) -> Bool) {
            remove { !isFresh($0) }
        }
    }

    private struct SyncSchedule {
        let types: SyncTypeFlags
        let interval: TimeInterval
        var lastSent: Date
    }

    public struct Config {
        public var seenCapacity: Int = 1000          // max packets per sync (cap across types)
        public var gcsMaxBytes: Int = 400           // filter size budget (128..1024)
        public var gcsTargetFpr: Double = 0.01      // 1%
        public var maxMessageAgeSeconds: TimeInterval = 900  // 15 min - discard older messages
        public var maintenanceIntervalSeconds: TimeInterval = 30.0
        public var stalePeerCleanupIntervalSeconds: TimeInterval = 60.0
        public var stalePeerTimeoutSeconds: TimeInterval = 60.0
        public var fragmentCapacity: Int = 600
        public var fileTransferCapacity: Int = 200
        public var fragmentSyncIntervalSeconds: TimeInterval = 30.0
        public var fileTransferSyncIntervalSeconds: TimeInterval = 60.0
        public var messageSyncIntervalSeconds: TimeInterval = 15.0
        // Nuevas configuraciones para seguridad
        public var rateLimitPacketsPerSecond: Double = 10.0  // Rate limiting para prevenir DoS
        public var timestampToleranceSeconds: TimeInterval = 300.0  // Tolerancia para manipulación de timestamps (5 min)
        public var enableSignatureVerification: Bool = true  // Verificar firmas en recepción
        public var maxPayloadSizeBytes: Int = 1024  // Límite de tamaño de payload para prevenir DoS
        public var enableContentValidation: Bool = false  // Validar contenido de paquetes
        public var gcsMinTargetFpr: Double = 0.0001  // Mínimo FPR para GCS
        public var gcsMaxTargetFpr: Double = 0.25   // Máximo FPR para GCS

        public init(
            seenCapacity: Int = 1000,
            gcsMaxBytes: Int = 400,
            gcsTargetFpr: Double = 0.01,
            maxMessageAgeSeconds: TimeInterval = 900,
            maintenanceIntervalSeconds: TimeInterval = 30.0,
            stalePeerCleanupIntervalSeconds: TimeInterval = 60.0,
            stalePeerTimeoutSeconds: TimeInterval = 60.0,
            fragmentCapacity: Int = 600,
            fileTransferCapacity: Int = 200,
            fragmentSyncIntervalSeconds: TimeInterval = 30.0,
            fileTransferSyncIntervalSeconds: TimeInterval = 60.0,
            messageSyncIntervalSeconds: TimeInterval = 15.0,
            rateLimitPacketsPerSecond: Double = 10.0,
            timestampToleranceSeconds: TimeInterval = 300.0,
            enableSignatureVerification: Bool = true,
            maxPayloadSizeBytes: Int = 1024,
            enableContentValidation: Bool = false,
            gcsMinTargetFpr: Double = 0.0001,
            gcsMaxTargetFpr: Double = 0.25
        ) {
            self.seenCapacity = seenCapacity
            self.gcsMaxBytes = gcsMaxBytes
            self.gcsTargetFpr = gcsTargetFpr
            self.maxMessageAgeSeconds = maxMessageAgeSeconds
            self.maintenanceIntervalSeconds = maintenanceIntervalSeconds
            self.stalePeerCleanupIntervalSeconds = stalePeerCleanupIntervalSeconds
            self.stalePeerTimeoutSeconds = stalePeerTimeoutSeconds
            self.fragmentCapacity = fragmentCapacity
            self.fileTransferCapacity = fileTransferCapacity
            self.fragmentSyncIntervalSeconds = fragmentSyncIntervalSeconds
            self.fileTransferSyncIntervalSeconds = fileTransferSyncIntervalSeconds
            self.messageSyncIntervalSeconds = messageSyncIntervalSeconds
            self.rateLimitPacketsPerSecond = rateLimitPacketsPerSecond
            self.timestampToleranceSeconds = timestampToleranceSeconds
            self.enableSignatureVerification = enableSignatureVerification
            self.maxPayloadSizeBytes = maxPayloadSizeBytes
            self.enableContentValidation = enableContentValidation
            self.gcsMinTargetFpr = gcsMinTargetFpr
            self.gcsMaxTargetFpr = gcsMaxTargetFpr
        }
    }

    public weak var delegate: GossipSyncManagerDelegate?
    private var isRunning = false
    private let myPeerID: PeerID
    private let config: Config
    private let requestSyncManager: RequestSyncManager

    // Storage: broadcast packets by type, and latest announce per sender
    private var messages = PacketStore()
    private var fragments = PacketStore()
    private var fileTransfers = PacketStore()
    private var latestAnnouncementByPeer: [PeerID: (id: String, packet: BitPacket)] = [:]
    
    // Security: rate limiting tracker
    private var packetRateTracker: [PeerID: [TimeInterval]] = [:]

    // Timer
    private var periodicTimer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "mesh.sync", qos: .utility)
    private var lastStalePeerCleanup: Date = .distantPast
    private var syncSchedules: [SyncSchedule] = []

    public init(myPeerID: PeerID, config: Config = Config(), requestSyncManager: RequestSyncManager) {
        self.myPeerID = myPeerID
        self.config = config
        self.requestSyncManager = requestSyncManager
        var schedules: [SyncSchedule] = []
        if config.seenCapacity > 0 && config.messageSyncIntervalSeconds > 0 {
            schedules.append(SyncSchedule(types: .publicMessages, interval: config.messageSyncIntervalSeconds, lastSent: .distantPast))
        }
        if config.fragmentCapacity > 0 && config.fragmentSyncIntervalSeconds > 0 {
            schedules.append(SyncSchedule(types: .fragment, interval: config.fragmentSyncIntervalSeconds, lastSent: .distantPast))
        }
        if config.fileTransferCapacity > 0 && config.fileTransferSyncIntervalSeconds > 0 {
            schedules.append(SyncSchedule(types: .fileTransfer, interval: config.fileTransferSyncIntervalSeconds, lastSent: .distantPast))
        }
        syncSchedules = schedules
    }

    public func start() {
        isRunning = true
        stop()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        let interval = max(0.1, config.maintenanceIntervalSeconds)
        timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .seconds(1))
        timer.setEventHandler { [weak self] in
            self?.performPeriodicMaintenance()
        }
        timer.resume()
        periodicTimer = timer
    }

    public func stop() {
        isRunning = false
        periodicTimer?.cancel(); periodicTimer = nil
    }

    public func scheduleInitialSyncToPeer(_ peerID: PeerID, delaySeconds: TimeInterval = 5.0) {
        queue.asyncAfter(deadline: .now() + delaySeconds) { [weak self] in
            guard let self = self else { return }
            self.sendRequestSync(to: peerID, types: .publicMessages)
            if self.config.fragmentCapacity > 0 && self.config.fragmentSyncIntervalSeconds > 0 {
                self.queue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.sendRequestSync(to: peerID, types: .fragment)
                }
            }
            if self.config.fileTransferCapacity > 0 && self.config.fileTransferSyncIntervalSeconds > 0 {
                self.queue.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.sendRequestSync(to: peerID, types: .fileTransfer)
                }
            }
        }
    }

    public func onPublicPacketSeen(_ packet: BitPacket) {
        queue.async { [weak self] in
            self?._onPublicPacketSeen(packet)
        }
    }

    public func onPrivatePacketSeen(_ packet: BitPacket) {
        // Handle private packet for gossip sync
    }

    public func removeAnnouncementForPeer(_ peerID: PeerID) {
        queue.async { [weak self] in
            self?.removeState(for: peerID)
        }
    }

    public func handleRequestSync(from peerID: PeerID, request: RequestSyncPacket) {
        queue.async { [weak self] in
            self?._handleRequestSync(from: peerID, request: request)
        }
    }

    // Helper to check if a packet is within the age threshold
    private func isPacketFresh(_ packet: BitPacket) -> Bool {
        let nowMs = UInt64(Date().timeIntervalSince1970 * 1000)
        let ageThresholdMs = UInt64(config.maxMessageAgeSeconds * 1000)
        let toleranceMs = UInt64(config.timestampToleranceSeconds * 1000)

        // If current time is less than threshold, accept all (handle clock issues gracefully)
        guard nowMs >= ageThresholdMs else { return true }

        let cutoffMs = nowMs - ageThresholdMs
        let futureCutoffMs = nowMs + toleranceMs
        return packet.timestamp >= cutoffMs && packet.timestamp <= futureCutoffMs
    }

    private func isAnnouncementFresh(_ packet: BitPacket) -> Bool {
        guard config.stalePeerTimeoutSeconds > 0 else { return true }
        let nowMs = UInt64(Date().timeIntervalSince1970 * 1000)
        let timeoutMs = UInt64(config.stalePeerTimeoutSeconds * 1000)
        guard nowMs >= timeoutMs else { return true }
        let cutoffMs = nowMs - timeoutMs
        return packet.timestamp >= cutoffMs
    }

    private func checkRateLimit(for peerID: PeerID) -> Bool {
        let now = Date().timeIntervalSince1970
        var timestamps = packetRateTracker[peerID] ?? []
        // Remove timestamps older than 1 second
        timestamps = timestamps.filter { now - $0 < 1.0 }
        // Check if under limit
        if Double(timestamps.count) < config.rateLimitPacketsPerSecond {
            timestamps.append(now)
            packetRateTracker[peerID] = timestamps
            return true
        } else {
            return false
        }
    }

    private func validatePacketContent(_ packet: BitPacket) -> Bool {
        // Validación básica: verificar que el payload no contenga patrones maliciosos
        // Por ejemplo, evitar payloads con secuencias de bytes específicas
        // Esto es un placeholder; en implementación real, usar antivirus o validadores específicos
        let forbiddenPatterns = [Data([0xDE, 0xAD, 0xBE, 0xEF])]  // Ejemplo
        for pattern in forbiddenPatterns {
            if packet.payload.range(of: pattern) != nil {
                return false
            }
        }
        return true
    }

    private func _onPublicPacketSeen(_ packet: BitPacket) {
        guard let messageType = MessageType(rawValue: packet.type) else { return }
        let sender = PeerID(hexData: packet.senderID)
        
        // Rate limiting
        if !checkRateLimit(for: sender) {
            BitLogger.warning("Rate limit exceeded for peer \(sender)", category: .security)
            return
        }
        
        // Verificación de firma si habilitada
        if config.enableSignatureVerification && !delegate!.verifyPacketSignature(packet) {
            BitLogger.warning("Invalid signature for packet from \(sender)", category: .security)
            return
        }
        
        // Validación de tamaño de payload
        if packet.payload.count > config.maxPayloadSizeBytes {
            BitLogger.warning("Payload size \(packet.payload.count) exceeds limit \(config.maxPayloadSizeBytes) for peer \(sender)", category: .security)
            return
        }
        
        // Validación de contenido si habilitada
        if config.enableContentValidation {
            if !validatePacketContent(packet) {
                BitLogger.warning("Content validation failed for packet from \(sender)", category: .security)
                return
            }
        }
        
        let isBroadcastRecipient: Bool = {
            guard let r = packet.recipientID else { return true }
            return r.count == 8 && r.allSatisfy { $0 == 0xFF }
        }()

        switch messageType {
        case .announce:
            guard isPacketFresh(packet) else { return }
            guard isAnnouncementFresh(packet) else {
                let sender = PeerID(hexData: packet.senderID)
                removeState(for: sender)
                return
            }
            let idHex = PacketIdUtil.computeId(packet).hexEncodedString()
            let sender = PeerID(hexData: packet.senderID)
            latestAnnouncementByPeer[sender] = (id: idHex, packet: packet)
        case .message:
            guard isBroadcastRecipient else { return }
            guard isPacketFresh(packet) else { return }
            let idHex = PacketIdUtil.computeId(packet).hexEncodedString()
            messages.insert(idHex: idHex, packet: packet, capacity: max(1, config.seenCapacity))
        case .fragment:
            guard isBroadcastRecipient else { return }
            guard isPacketFresh(packet) else { return }
            let idHex = PacketIdUtil.computeId(packet).hexEncodedString()
            fragments.insert(idHex: idHex, packet: packet, capacity: max(1, config.fragmentCapacity))
        case .fileTransfer:
            guard isBroadcastRecipient else { return }
            guard isPacketFresh(packet) else { return }
            let idHex = PacketIdUtil.computeId(packet).hexEncodedString()
            fileTransfers.insert(idHex: idHex, packet: packet, capacity: max(1, config.fileTransferCapacity))
        default:
            break
        }
    }

    private func sendPeriodicSync(for types: SyncTypeFlags) {
        // Unicast sync to connected peers to allow RSR attribution
        if let connectedPeers = delegate?.getConnectedPeers(), !connectedPeers.isEmpty {
            BitLogger.debug("Sending periodic sync to \(connectedPeers.count) connected peers", category: .sync)
            for peerID in connectedPeers {
                sendRequestSync(to: peerID, types: types)
            }
        } else {
            // Fallback to broadcast (discovery phase)
            sendRequestSync(for: types)
        }
    }

    private func sendRequestSync(for types: SyncTypeFlags) {
        let payload = buildGcsPayload(for: types)
        let pkt = BitPacket(
            type: MessageType.requestSync.rawValue,
            senderID: Data(hexString: myPeerID.id) ?? Data(),
            recipientID: nil, // broadcast
            timestamp: UInt64(Date().timeIntervalSince1970 * 1000),
            payload: payload,
            signature: nil,
            ttl: 0 // local-only
        )
        let signed = delegate?.signPacketForBroadcast(pkt) ?? pkt
        delegate?.sendPacket(signed)
    }

    private func sendRequestSync(to peerID: PeerID, types: SyncTypeFlags) {
        // Register the request for RSR validation
        requestSyncManager.registerRequest(to: peerID)
        
        let payload = buildGcsPayload(for: types)
        var recipient = Data()
        var temp = peerID.id
        while temp.count >= 2 && recipient.count < 8 {
            let hexByte = String(temp.prefix(2))
            if let b = UInt8(hexByte, radix: 16) { recipient.append(b) }
            temp = String(temp.dropFirst(2))
        }
        let pkt = BitPacket(
            type: MessageType.requestSync.rawValue,
            senderID: Data(hexString: myPeerID.id) ?? Data(),
            recipientID: recipient,
            timestamp: UInt64(Date().timeIntervalSince1970 * 1000),
            payload: payload,
            signature: nil,
            ttl: 0 // local-only
        )
        let signed = delegate?.signPacketForBroadcast(pkt) ?? pkt
        delegate?.sendPacket(to: peerID, packet: signed)
    }

    private func _handleRequestSync(from peerID: PeerID, request: RequestSyncPacket) {
        let requestedTypes = (request.types ?? .publicMessages)
        // Decode GCS into sorted set and prepare membership checker
        let sorted = GCSFilter.decodeToSortedSet(p: request.p, m: request.m, data: request.data)
        func mightContain(_ id: Data) -> Bool {
            let bucket = GCSFilter.bucket(for: id, modulus: request.m)
            return GCSFilter.contains(sortedValues: sorted, candidate: bucket)
        }

        if requestedTypes.contains(MessageType.announce) {
            for (_, pair) in latestAnnouncementByPeer {
                let (idHex, pkt) = pair
                guard isPacketFresh(pkt) else { continue }
                let idBytes = Data(hexString: idHex) ?? Data()
                if !mightContain(idBytes) {
                    var toSend = pkt
                    toSend.ttl = 0
                    toSend.isRSR = true // Mark as solicited response
                    delegate?.sendPacket(to: peerID, packet: toSend)
                }
            }
        }

        if requestedTypes.contains(MessageType.message) {
            let toSendMsgs = messages.allPackets(isFresh: isPacketFresh)
            for pkt in toSendMsgs {
                let idBytes = PacketIdUtil.computeId(pkt)
                if !mightContain(idBytes) {
                    var toSend = pkt
                    toSend.ttl = 0
                    toSend.isRSR = true // Mark as solicited response
                    delegate?.sendPacket(to: peerID, packet: toSend)
                }
            }
        }

        if requestedTypes.contains(MessageType.fragment) {
            let frags = fragments.allPackets(isFresh: isPacketFresh)
            for pkt in frags {
                let idBytes = PacketIdUtil.computeId(pkt)
                if !mightContain(idBytes) {
                    var toSend = pkt
                    toSend.ttl = 0
                    toSend.isRSR = true // Mark as solicited response
                    delegate?.sendPacket(to: peerID, packet: toSend)
                }
            }
        }

        if requestedTypes.contains(MessageType.fileTransfer) {
            let files = fileTransfers.allPackets(isFresh: isPacketFresh)
            for pkt in files {
                let idBytes = PacketIdUtil.computeId(pkt)
                if !mightContain(idBytes) {
                    var toSend = pkt
                    toSend.ttl = 0
                    toSend.isRSR = true // Mark as solicited response
                    delegate?.sendPacket(to: peerID, packet: toSend)
                }
            }
        }
    }

    // Build REQUEST_SYNC payload using current candidates and GCS params
    private func buildGcsPayload(for types: SyncTypeFlags) -> Data {
        var candidates: [BitPacket] = []
        if types.contains(MessageType.announce) {
            for (_, pair) in latestAnnouncementByPeer where isPacketFresh(pair.packet) {
                candidates.append(pair.packet)
            }
        }
        if types.contains(MessageType.message) {
            candidates.append(contentsOf: messages.allPackets(isFresh: isPacketFresh))
        }
        if types.contains(MessageType.fragment) {
            candidates.append(contentsOf: fragments.allPackets(isFresh: isPacketFresh))
        }
        if types.contains(MessageType.fileTransfer) {
            candidates.append(contentsOf: fileTransfers.allPackets(isFresh: isPacketFresh))
        }
        if candidates.isEmpty {
            let p = GCSFilter.deriveP(targetFpr: config.gcsTargetFpr)
            let req = RequestSyncPacket(p: p, m: 1, data: Data(), types: types)
            return req.encode()
        }

        // Sort by timestamp desc
        candidates.sort { $0.timestamp > $1.timestamp }

        let p = GCSFilter.deriveP(targetFpr: config.gcsTargetFpr)
        let nMax = GCSFilter.estimateMaxElements(sizeBytes: config.gcsMaxBytes, p: p)
        let cap: Int
        if types == .fragment {
            cap = max(1, config.fragmentCapacity)
        } else if types == .fileTransfer {
            cap = max(1, config.fileTransferCapacity)
        } else {
            cap = max(1, config.seenCapacity)
        }
        let takeN = min(candidates.count, min(nMax, cap))
        if takeN <= 0 {
            let req = RequestSyncPacket(p: p, m: 1, data: Data(), types: types)
            return req.encode()
        }
        let ids: [Data] = candidates.prefix(takeN).map { PacketIdUtil.computeId($0) }
        let params = GCSFilter.buildFilter(ids: ids, maxBytes: config.gcsMaxBytes, targetFpr: config.gcsTargetFpr)
        let req = RequestSyncPacket(p: params.p, m: params.m, data: params.data, types: types)
        return req.encode()
    }

    // Periodic cleanup of expired messages and announcements
    private func cleanupExpiredMessages() {
        // Remove expired announcements
        latestAnnouncementByPeer = latestAnnouncementByPeer.filter { _, pair in
            isPacketFresh(pair.packet)
        }

        messages.removeExpired(isFresh: isPacketFresh)
        fragments.removeExpired(isFresh: isPacketFresh)
        fileTransfers.removeExpired(isFresh: isPacketFresh)
    }

    private func performPeriodicMaintenance(now: Date = Date()) {
        cleanupExpiredMessages()
        cleanupStaleAnnouncementsIfNeeded(now: now)
        requestSyncManager.cleanup() // Cleanup expired sync requests
        
        for index in syncSchedules.indices {
            guard syncSchedules[index].interval > 0 else { continue }
            if syncSchedules[index].lastSent == .distantPast || now.timeIntervalSince(syncSchedules[index].lastSent) >= syncSchedules[index].interval {
                syncSchedules[index].lastSent = now
                sendPeriodicSync(for: syncSchedules[index].types)
            }
        }
    }

    private func cleanupStaleAnnouncementsIfNeeded(now: Date) {
        guard now.timeIntervalSince(lastStalePeerCleanup) >= config.stalePeerCleanupIntervalSeconds else {
            return
        }
        lastStalePeerCleanup = now
        cleanupStaleAnnouncements(now: now)
    }

    private func cleanupStaleAnnouncements(now: Date) {
        let timeoutMs = UInt64(config.stalePeerTimeoutSeconds * 1000)
        let nowMs = UInt64(now.timeIntervalSince1970 * 1000)
        guard nowMs >= timeoutMs else { return }
        let cutoff = nowMs - timeoutMs
        let stalePeerIDs = latestAnnouncementByPeer.compactMap { peerID, pair in
            pair.packet.timestamp < cutoff ? peerID : nil
        }
        guard !stalePeerIDs.isEmpty else { return }
        for peerKey in stalePeerIDs {
            removeState(for: peerKey)
        }
    }

    private func removeState(for peerID: PeerID) {
        _ = latestAnnouncementByPeer.removeValue(forKey: peerID)
        messages.remove { PeerID(hexData: $0.senderID) == peerID }
        fragments.remove { PeerID(hexData: $0.senderID) == peerID }
        fileTransfers.remove { PeerID(hexData: $0.senderID) == peerID }
    }
}

    public func onPublicPacketSeen(_ packet: BitPacket) {
        // Stub implementation
    }
    
    public func removeAnnouncementForPeer(_ peerID: PeerID) {
        // Stub implementation
    }