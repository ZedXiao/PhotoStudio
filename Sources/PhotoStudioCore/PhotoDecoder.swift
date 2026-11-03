import Foundation
import CoreImage
import ImageIO
import CLibRawBridge

public final class DecodeCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    public init() {}
    public func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    public var isCancelled: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
    public func check() throws { if isCancelled { throw CancellationError() } }
}

public struct PhotoMetadata: Sendable {
    public var make = ""
    public var model = ""
    public var lens = ""
    public var iso: Double?
    public var aperture: Double?
    public var shutter: Double?
    public var focalLength: Double?
    public var capturedAt = ""
    public var camera: String {
        if model.lowercased().hasPrefix(make.lowercased()) { return model }
        return [make, model].filter { !$0.isEmpty }.joined(separator: " ")
    }
    public init() {}
    public var exposureDescription: String {
        var parts: [String] = []
        if let focalLength, focalLength > 0 { parts.append(String(format: "%.0f mm", focalLength)) }
        if let aperture, aperture > 0 { parts.append(String(format: "ƒ/%.1f", aperture)) }
        if let shutter, shutter > 0 {
            parts.append(shutter < 1 ? "1/\(Int((1 / shutter).rounded())) s" : String(format: "%.1f s", shutter))
        }
        if let iso, iso > 0 { parts.append("ISO \(Int(iso))") }
        return parts.joined(separator: "   ·   ")
    }
}

public struct DecodedPhoto: @unchecked Sendable {
    public let image: CGImage
    public let metadata: PhotoMetadata
    public let engine: String
    public var byteCost: Int { image.bytesPerRow * image.height }
    public init(image: CGImage, metadata: PhotoMetadata, engine: String) {
        self.image = image; self.metadata = metadata; self.engine = engine
    }
}

public struct PhotoDecodeError: LocalizedError {
    public let message: String
    public var errorDescription: String? { message }
    public init(_ message: String) { self.message = message }
}

public protocol PhotoDecoder: Sendable {
    func decode(_ asset: PhotoAsset, cancellation: DecodeCancellation) throws -> DecodedPhoto
}

public enum MetadataReader {
    public static func read(_ url: URL, properties: [CFString: Any]? = nil) -> PhotoMetadata {
        let values = properties ?? CGImageSourceCreateWithURL(url as CFURL, nil).flatMap {
            CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any]
        } ?? [:]
        let tiff = values[kCGImagePropertyTIFFDictionary] as? [CFString: Any] ?? [:]
        let exif = values[kCGImagePropertyExifDictionary] as? [CFString: Any] ?? [:]
        var info = PhotoMetadata()
        info.make = tiff[kCGImagePropertyTIFFMake] as? String ?? ""
        info.model = tiff[kCGImagePropertyTIFFModel] as? String ?? ""
        info.lens = exif[kCGImagePropertyExifLensModel] as? String ?? ""
        info.aperture = (exif[kCGImagePropertyExifFNumber] as? NSNumber)?.doubleValue
        info.shutter = (exif[kCGImagePropertyExifExposureTime] as? NSNumber)?.doubleValue
        info.iso = (exif[kCGImagePropertyExifISOSpeedRatings] as? [NSNumber])?.first?.doubleValue
        info.focalLength = (exif[kCGImagePropertyExifFocalLength] as? NSNumber)?.doubleValue
        info.capturedAt = exif[kCGImagePropertyExifDateTimeOriginal] as? String ?? ""
        return info
    }
}

public final class StandardPhotoDecoder: PhotoDecoder, @unchecked Sendable {
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    public init() {}
    public static var libRawVersion: String { String(cString: ps_raw_version()) }
    public static var libRawCameras: [String] {
        (0..<ps_raw_camera_count()).map { String(cString: ps_raw_camera_at($0)) }
    }
    public static var systemCameras: [String] { CIRAWFilter.supportedCameraModels }
    public static func rawOrientation(_ url: URL) -> Int32 { ps_raw_orientation(url.path) }

    public func decode(_ asset: PhotoAsset, cancellation: DecodeCancellation = DecodeCancellation()) throws -> DecodedPhoto {
        try cancellation.check()
        if asset.isRaw {
            if let filter = CIRAWFilter(imageURL: asset.url) {
                // Some system readers use the embedded JPEG's orientation instead of the RAW IFD.
                // Use the sensor image orientation for both decoding engines.
                let orientation = Self.rawOrientation(asset.url)
                if let value = CGImagePropertyOrientation(rawValue: UInt32(max(0, orientation))) {
                    filter.orientation = value
                }
                filter.scaleFactor = 1
                filter.isDraftModeEnabled = false
                if let output = filter.outputImage,
                   let image = context.createCGImage(output, from: output.extent, format: .RGBA8, colorSpace: colorSpace) {
                    try cancellation.check()
                    let info = MetadataReader.read(asset.url, properties: filter.properties as? [CFString: Any])
                    return DecodedPhoto(image: image, metadata: info, engine: "Apple RAW")
                }
            }
            try cancellation.check()
            return try decodeWithLibRaw(asset, cancellation: cancellation)
        }
        guard let source = CGImageSourceCreateWithURL(asset.url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else {
            throw PhotoDecodeError("无法打开这张图片。文件可能已损坏、被移动，或使用了暂不支持的编码。")
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.int32Value ?? 1
        let displayed = try ImageOrientation.normalized(image, orientation: orientation)
        try cancellation.check()
        return DecodedPhoto(image: displayed, metadata: MetadataReader.read(asset.url, properties: properties), engine: "ImageIO")
    }

    public func decodeWithLibRaw(_ asset: PhotoAsset, cancellation: DecodeCancellation = DecodeCancellation()) throws -> DecodedPhoto {
        try cancellation.check()
        var result = PSRawImage()
        var errorBuffer = [CChar](repeating: 0, count: 512)
        let opaque = Unmanaged.passUnretained(cancellation).toOpaque()
        let code = ps_raw_decode(asset.url.path, { context in
            guard let context else { return 0 }
            return Unmanaged<DecodeCancellation>.fromOpaque(context).takeUnretainedValue().isCancelled ? 1 : 0
        }, opaque, &result, &errorBuffer, errorBuffer.count)
        defer { ps_raw_free(&result) }
        try cancellation.check()
        guard code == 0, let pixels = result.pixels else {
            throw PhotoDecodeError("此 RAW 暂时无法解码。系统解码器和 LibRaw 均未能打开该文件。\nLibRaw：\(String(cString: errorBuffer))\n请检查相机型号、RAW 压缩方式或文件完整性。")
        }
        guard let provider = CGDataProvider(dataInfo: nil, data: pixels, size: result.byte_count, releaseData: { _, bytes, _ in
            free(UnsafeMutableRawPointer(mutating: bytes))
        }) else { throw PhotoDecodeError("没有足够的内存显示这张 RAW。") }
        result.pixels = nil // the provider now owns the buffer
        let flags = CGBitmapInfo.byteOrder16Little
        guard let image = CGImage(width: Int(result.width), height: Int(result.height), bitsPerComponent: 16,
            bitsPerPixel: 48, bytesPerRow: Int(result.width) * 6, space: colorSpace, bitmapInfo: flags,
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            throw PhotoDecodeError("RAW 已解码，但无法生成预览图像。")
        }
        var info = MetadataReader.read(asset.url)
        let make = withUnsafePointer(to: &result.make) { $0.withMemoryRebound(to: CChar.self, capacity: 128) { String(cString: $0) } }
        let model = withUnsafePointer(to: &result.model) { $0.withMemoryRebound(to: CChar.self, capacity: 128) { String(cString: $0) } }
        if info.make.isEmpty { info.make = make }; if info.model.isEmpty { info.model = model }
        if info.iso == nil { info.iso = Double(result.iso) }
        if info.aperture == nil { info.aperture = Double(result.aperture) }
        if info.shutter == nil { info.shutter = Double(result.shutter) }
        if info.focalLength == nil { info.focalLength = Double(result.focal_length) }
        return DecodedPhoto(image: image, metadata: info, engine: "LibRaw \(Self.libRawVersion)")
    }
}
