// AnnouncementPacket.swift
import Foundation

public struct AnnouncementPacket {
    public let nickname: String
    public let noisePublicKey: Data
    public let signingPublicKey: Data
    public let directNeighbors: [Data]?
    public let applicationInfo: ApplicationInfo?

    public init(nickname: String, noisePublicKey: Data, signingPublicKey: Data, directNeighbors: [Data]? = nil, applicationInfo: ApplicationInfo? = nil) {
        self.nickname = nickname
        self.noisePublicKey = noisePublicKey
        self.signingPublicKey = signingPublicKey
        self.directNeighbors = directNeighbors
        self.applicationInfo = applicationInfo
    }

    public static func decode(from data: Data) -> AnnouncementPacket? {
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(AnnouncementPacket.self, from: data)
            return decoded
        } catch {
            print("Failed to decode AnnouncementPacket: \(error)")
            return nil
        }
    }

    public func encode() -> Data? {
        do {
            let encoder = JSONEncoder()
            return try encoder.encode(self)
        } catch {
            print("Failed to encode AnnouncementPacket: \(error)")
            return nil
        }
    }
}

// MARK: - Codable
extension AnnouncementPacket: Codable {
    private enum CodingKeys: String, CodingKey {
        case nickname
        case noisePublicKey
        case signingPublicKey
        case directNeighbors
        case applicationInfo
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decode(String.self, forKey: .nickname)
        noisePublicKey = try container.decode(Data.self, forKey: .noisePublicKey)
        signingPublicKey = try container.decode(Data.self, forKey: .signingPublicKey)
        directNeighbors = try container.decodeIfPresent([Data].self, forKey: .directNeighbors)
        applicationInfo = try container.decodeIfPresent(ApplicationInfo.self, forKey: .applicationInfo)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(noisePublicKey, forKey: .noisePublicKey)
        try container.encode(signingPublicKey, forKey: .signingPublicKey)
        try container.encodeIfPresent(directNeighbors, forKey: .directNeighbors)
        try container.encodeIfPresent(applicationInfo, forKey: .applicationInfo)
    }
}