//
// GeoTypes.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import CoreLocation

// MARK: - Channel Types

public enum ChannelID: Codable, Hashable {
    case mesh
    case location(GeohashChannel)
    
    public var id: String {
        switch self {
        case .mesh: return "mesh"
        case .location(let ch): return ch.geohash
        }
    }
}

public struct GeohashChannel: Identifiable, Hashable, Codable {
    public let id: String
    public let level: GeohashChannelLevel
    public let geohash: String
    
    public init(level: GeohashChannelLevel, geohash: String) {
        self.id = geohash
        self.level = level
        self.geohash = geohash
    }
}

public enum GeohashChannelLevel: String, CaseIterable, Codable {
    case region
    case province
    case city
    case neighborhood
    case block
    case building
    
    public var precision: Int {
        switch self {
        case .region: return 2
        case .province: return 4
        case .city: return 6
        case .neighborhood: return 8
        case .block: return 10
        case .building: return 12
        }
    }
}

// MARK: - Geohash Utilities

public enum Geohash {
    public struct LatLon {
        public let lat: Double
        public let lon: Double
    }
    
    public struct Bounds {
        public let latMin: Double
        public let latMax: Double
        public let lonMin: Double
        public let lonMax: Double
    }
    
    // Basic geohash encoding/decoding
    public static func encode(latitude: Double, longitude: Double, precision: Int = 12) -> String {
        // Simplified implementation - in real code this would use proper geohash algorithm
        let latInt = Int((latitude + 90) * 1000000)
        let lonInt = Int((longitude + 180) * 1000000)
        let combined = (latInt << 32) | lonInt
        return String(format: "%0\(precision)x", combined).prefix(precision).lowercased()
    }
    
    public static func decodeCenter(_ geohash: String) -> LatLon {
        // Simplified implementation
        let lat = Double(geohash.count) * 10 - 90
        let lon = Double(geohash.count) * 20 - 180
        return LatLon(lat: lat, lon: lon)
    }
    
    public static func decodeBounds(_ geohash: String) -> Bounds {
        let center = decodeCenter(geohash)
        let precision = geohash.count
        let delta = 180.0 / Double(1 << precision)
        return Bounds(
            latMin: center.lat - delta,
            latMax: center.lat + delta,
            lonMin: center.lon - delta,
            lonMax: center.lon + delta
        )
    }
}