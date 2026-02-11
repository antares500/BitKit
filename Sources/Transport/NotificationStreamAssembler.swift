//
// NotificationStreamAssembler.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation

/// Assembles notification streams
public struct NotificationStreamAssembler {
    private var buffer = Data()
    private var pendingFrameStartedAt: DispatchTime?
    private var pendingFrameExpectedLength: Int = 0

    public init() {}
    
    private mutating func resetState() {
        buffer.removeAll(keepingCapacity: false)
        pendingFrameStartedAt = nil
        pendingFrameExpectedLength = 0
    }

    public mutating func append(_ chunk: Data) -> AppendResult {
        guard !chunk.isEmpty else { return AppendResult(droppedPrefixes: [], assembledPackets: [], reset: false) }

        buffer.append(chunk)

        var frames: [Data] = []
        var dropped: [Data] = []
        var didReset = false
        let now = DispatchTime.now()
        let maxFrameLength = 512 // Assuming a default, adjust if needed
        let minimumFramePrefix = 8 + 8 // Assuming header + senderID

        if buffer.count > 1024 { // Hard cap
            resetState()
            return AppendResult(droppedPrefixes: [], assembledPackets: [], reset: true)
        }

        while buffer.count >= minimumFramePrefix {
            guard let version = buffer.first else { break }
            guard version == 1 || version == 2 else {
                dropped.append(Data([buffer.removeFirst()]))
                pendingFrameStartedAt = nil
                pendingFrameExpectedLength = 0
                continue
            }

            // Simplified parsing, assuming v1 for now
            let framePrefix = 8 + 8 // header + senderID
            guard buffer.count >= framePrefix else { break }

            // Assume payload length at offset 12-13 for v1
            let lengthIndex = buffer.startIndex + 12
            guard lengthIndex + 1 < buffer.endIndex else { break }
            let payloadLength = (Int(buffer[lengthIndex]) << 8) | Int(buffer[lengthIndex + 1])

            let frameLength = framePrefix + payloadLength
            // Add recipient if hasRecipient, etc. Simplified.

            guard frameLength > 0, frameLength <= maxFrameLength else {
                resetState()
                didReset = true
                break
            }

            if buffer.count < frameLength {
                // Wait for more data
                if pendingFrameStartedAt == nil {
                    pendingFrameStartedAt = now
                    pendingFrameExpectedLength = frameLength
                }
                break
            }

            pendingFrameStartedAt = nil
            pendingFrameExpectedLength = 0

            let frame = Data(buffer.prefix(frameLength))
            frames.append(frame)
            buffer.removeFirst(frameLength)
        }

        return AppendResult(droppedPrefixes: dropped, assembledPackets: frames, reset: didReset)
    }
}

public struct AppendResult {
    public let droppedPrefixes: [Data]
    public let assembledPackets: [Data]
    public let reset: Bool
    
    public init(droppedPrefixes: [Data], assembledPackets: [Data], reset: Bool = false) {
        self.droppedPrefixes = droppedPrefixes
        self.assembledPackets = assembledPackets
        self.reset = reset
    }
}