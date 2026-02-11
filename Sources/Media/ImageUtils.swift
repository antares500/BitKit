import Foundation
import ImageIO
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
import AVFoundation
#else
import AppKit
#endif

enum MediaUtilsError: Error {
    case invalidImage
    case encodingFailed
    case invalidVideo
    case videoCompressionFailed
    case invalidFile
    case fileTooLarge
    case unsupportedFileType
}

enum MediaUtils {
    private static let compressionQuality: CGFloat = 0.82
    private static let targetImageBytes: Int = 45_000
    private static let maxVideoSize: Int64 = 50 * 1024 * 1024  // 50MB
    private static let maxFileSize: Int64 = 10 * 1024 * 1024   // 10MB
    private static let supportedFileTypes: [String] = ["pdf", "txt", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "zip", "rar"]

    // Existing image processing functions
    static func processImage(at url: URL, maxDimension: CGFloat = 448) throws -> URL {
        // Security H1: Check file size BEFORE reading into memory
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attrs[.size] as? Int else {
            throw MediaUtilsError.invalidImage
        }
        // Allow up to 10MB source images (will be scaled down)
        guard fileSize <= 10 * 1024 * 1024 else {
            throw MediaUtilsError.invalidImage
        }

        let data = try Data(contentsOf: url)
        #if os(iOS)
        guard let image = UIImage(data: data) else { throw MediaUtilsError.invalidImage }
        return try processImage(image, maxDimension: maxDimension)
        #else
        guard let image = NSImage(data: data) else { throw MediaUtilsError.invalidImage }
        return try processImage(image, maxDimension: maxDimension)
        #endif
    }

    #if os(iOS)
    static func processImage(_ image: UIImage, maxDimension: CGFloat = 448) throws -> URL {
        return try autoreleasepool {
            // Scale the image first
            let scaled = scaledImage(image, maxDimension: maxDimension)

            // Get CGImage from UIImage - this is the key to stripping metadata
            guard let cgImage = scaled.cgImage else {
                throw MediaUtilsError.encodingFailed
            }

            // Use CGImageDestination to encode without metadata (same as macOS)
            var quality = compressionQuality
            guard var jpegData = encodeJPEG(from: cgImage, quality: quality) else {
                throw MediaUtilsError.encodingFailed
            }

            // Compress to target size
            while jpegData.count > targetImageBytes && quality > 0.3 {
                quality -= 0.1
                autoreleasepool {
                    if let next = encodeJPEG(from: cgImage, quality: quality) {
                        jpegData = next
                    }
                }
            }

            let outputURL = try makeOutputURL(for: "img", extension: "jpg")
            try jpegData.write(to: outputURL, options: .atomic)
            return outputURL
        }
    }

    private static func scaledImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        // Draw into a new context to get a clean CGImage without metadata
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let rendered = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rendered ?? image
    }
    #else
    static func processImage(_ image: NSImage, maxDimension: CGFloat = 448) throws -> URL {
        return try autoreleasepool {
            let scaled = scaledImage(image, maxDimension: maxDimension)
            guard let inputCG = scaled.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw MediaUtilsError.encodingFailed
            }
            let width = inputCG.width
            let height = inputCG.height
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw MediaUtilsError.encodingFailed
            }
            context.draw(inputCG, in: CGRect(x: 0, y: 0, width: width, height: height))
            guard let cgImage = context.makeImage() else {
                throw MediaUtilsError.encodingFailed
            }
            var quality = compressionQuality
            guard var jpegData = encodeJPEG(from: cgImage, quality: quality) else {
                throw MediaUtilsError.encodingFailed
            }
            while jpegData.count > targetImageBytes && quality > 0.3 {
                quality -= 0.1
                autoreleasepool {
                    if let next = encodeJPEG(from: cgImage, quality: quality) {
                        jpegData = next
                    }
                }
            }
            let outputURL = try makeOutputURL(for: "img", extension: "jpg")
            try jpegData.write(to: outputURL, options: .atomic)
            return outputURL
        }
    }

    private static func scaledImage(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        let scaledImage = NSImage(size: newSize)
        scaledImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        scaledImage.unlockFocus()
        return scaledImage
    }
    #endif

    // Shared EXIF-stripping JPEG encoder for both iOS and macOS
    private static func encodeJPEG(from cgImage: CGImage, quality: CGFloat) -> Data? {
        guard let data = CFDataCreateMutable(nil, 0) else {
            return nil
        }
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        // Security: Strip ALL metadata (EXIF, GPS, TIFF, IPTC, XMP)
        // By only specifying compression quality and no metadata keys,
        // we ensure a clean JPEG with no privacy-leaking information
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return data as Data
    }

    // Video processing
    #if os(iOS)
    static func processVideo(at url: URL) async throws -> URL {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attrs[.size] as? Int64 else {
            throw MediaUtilsError.invalidVideo
        }
        guard fileSize <= maxVideoSize else {
            throw MediaUtilsError.fileTooLarge
        }

        let asset = AVAsset(url: url)
        guard try await asset.load(.isPlayable) else {
            throw MediaUtilsError.invalidVideo
        }

        // Compress video to H.264 with lower bitrate
        let outputURL = try await makeOutputURL(for: "vid", extension: "mp4")
        try await compressVideo(asset: asset, outputURL: outputURL)
        return outputURL
    }

    private static func compressVideo(asset: AVAsset, outputURL: URL) async throws {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            throw MediaUtilsError.videoCompressionFailed
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        await exportSession.export()

        if exportSession.status != .completed {
            throw MediaUtilsError.videoCompressionFailed
        }
    }
    #else
    // macOS video processing - basic copy for now, can extend with AVFoundation if needed
    static func processVideo(at url: URL) throws -> URL {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attrs[.size] as? Int64 else {
            throw MediaUtilsError.invalidVideo
        }
        guard fileSize <= maxVideoSize else {
            throw MediaUtilsError.fileTooLarge
        }

        // For macOS, just copy the file (extend with compression if needed)
        let outputURL = try makeOutputURL(for: "vid", extension: url.pathExtension)
        try FileManager.default.copyItem(at: url, to: outputURL)
        return outputURL
    }
    #endif

    // File processing
    static func processFile(at url: URL) throws -> URL {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attrs[.size] as? Int64 else {
            throw MediaUtilsError.invalidFile
        }
        guard fileSize <= maxFileSize else {
            throw MediaUtilsError.fileTooLarge
        }

        let fileExtension = url.pathExtension.lowercased()
        guard supportedFileTypes.contains(fileExtension) else {
            throw MediaUtilsError.unsupportedFileType
        }

        // Copy file to outgoing directory
        let outputURL = try makeOutputURL(for: "file", extension: fileExtension)
        try FileManager.default.copyItem(at: url, to: outputURL)
        return outputURL
    }

    private static func makeOutputURL(for prefix: String, extension ext: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = "\(prefix)_\(formatter.string(from: Date())).\(ext)"

        let directory = try applicationFilesDirectory().appendingPathComponent("media/outgoing", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        return directory.appendingPathComponent(fileName)
    }

    private static func applicationFilesDirectory() throws -> URL {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return base.appendingPathComponent("files", isDirectory: true)
    }
}
