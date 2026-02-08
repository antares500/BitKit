// MimeType.swift
import Foundation

public enum MimeType: String, CaseIterable, Hashable {
    case jpeg = "image/jpeg"
    case jpg = "image/jpg"
    case png = "image/png"
    case gif = "image/gif"
    case webp = "image/webp"
    case mp4Audio = "audio/mp4"
    case m4a = "audio/m4a"
    case aac = "audio/aac"
    case mpeg = "audio/mpeg"
    case mp3 = "audio/mp3"
    case wav = "audio/wav"
    case xWav = "audio/x-wav"
    case ogg = "audio/ogg"
    case pdf = "application/pdf"
    case octetStream = "application/octet-stream"

    public var category: Category {
        switch self {
        case .jpeg, .jpg, .png, .gif, .webp:
            return .image
        case .aac, .m4a, .mp4Audio, .mpeg, .mp3, .wav, .xWav, .ogg:
            return .audio
        case .pdf, .octetStream:
            return .file
        }
    }

    public var isAllowed: Bool {
        return Self.allowed.contains(self)
    }

    public static var allowed: Set<MimeType> = [
        .jpeg, .jpg, .png, .gif, .webp,
        .mp4Audio, .m4a, .aac, .mpeg, .mp3,
        .wav, .xWav, .ogg,
        .pdf, .octetStream
    ]

    public var defaultExtension: String {
        switch self {
        case .jpeg, .jpg:           return "jpg"
        case .png:                  return "png"
        case .webp:                 return "webp"
        case .gif:                  return "gif"
        case .mp4Audio, .m4a, .aac: return "m4a"
        case .mpeg, .mp3:           return "mp3"
        case .wav, .xWav:           return "wav"
        case .ogg:                  return "ogg"
        case .pdf:                  return "pdf"
        case .octetStream:          return "bin"
        }
    }

    public func matches(data: Data) -> Bool {
        guard !data.isEmpty else { return false }
        if self == .octetStream { return true }

        switch self {
        case .jpeg, .jpg:
            return data.count >= 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF
        case .png:
            return data.count >= 8 &&
                   data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 &&
                   data[4] == 0x0D && data[5] == 0x0A && data[6] == 0x1A && data[7] == 0x0A
        case .gif:
            return data.count >= 6 && data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 &&
                   data[3] == 0x38 && (data[4] == 0x37 || data[4] == 0x39) && data[5] == 0x61
        case .webp:
            return data.count >= 12 &&
                   data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
                   data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50
        case .m4a, .mp4Audio, .aac:
            return data.count > 100
        case .mpeg, .mp3:
            if data.count >= 3 && data[0] == 0x49 && data[1] == 0x44 && data[2] == 0x33 {
                return true
            }
            return data.count >= 2 && data[0] == 0xFF && (data[1] & 0xE0) == 0xE0
        case .wav, .xWav:
            return data.count >= 12 &&
                   data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
                   data[8] == 0x57 && data[9] == 0x41 && data[10] == 0x56 && data[11] == 0x45
        case .ogg:
            return data.count >= 4 &&
                   data[0] == 0x4F && data[1] == 0x67 && data[2] == 0x67 && data[3] == 0x53
        case .pdf:
            return data.count >= 4 &&
                   data[0] == 0x25 && data[1] == 0x50 && data[2] == 0x44 && data[3] == 0x46
        default:
            return false
        }
    }

    public init?(rawValue: String) {
        let normalized = rawValue.lowercased()
        if let match = MimeType.allCases.first(where: { $0.rawValue == normalized }) {
            self = match
        } else {
            return nil
        }
    }
}

public extension MimeType {
    enum Category: String {
        case audio, image, file
    }
}