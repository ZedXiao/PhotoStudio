import Foundation
import CoreImage
import ImageIO
import CLibRawBridge

public enum ThumbnailDecoder {
    public static func decode(_ asset: PhotoAsset, maxPixelSize: Int = 256) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: !asset.isRaw,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: !asset.isRaw,
            kCGImageSourceShouldCacheImmediately: true
        ]
        if let source = CGImageSourceCreateWithURL(asset.url as CFURL, nil),
           let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) { return image }
        guard asset.isRaw else { return nil }
        var result = PSRawImage()
        let status = ps_raw_thumbnail(asset.url.path, &result)
        defer { ps_raw_free(&result) }
        guard status == 0, let pixels = result.pixels else { return nil }
        var image: CGImage?
        if result.encoded != 0 {
            let data = Data(bytes: pixels, count: result.byte_count)
            if let source = CGImageSourceCreateWithData(data as CFData, nil) {
                // Rotate explicitly using the RAW orientation, not inconsistently tagged embedded JPEGs.
                var opts = options
                opts[kCGImageSourceCreateThumbnailFromImageAlways] = true
                opts[kCGImageSourceCreateThumbnailWithTransform] = false
                image = CGImageSourceCreateThumbnailAtIndex(source, 0, opts as CFDictionary)
            }
        } else if result.channels == 3, result.bits == 8 {
            let data = Data(bytes: pixels, count: result.byte_count)
            if let provider = CGDataProvider(data: data as CFData) {
                image = CGImage(width: Int(result.width), height: Int(result.height), bitsPerComponent: 8, bitsPerPixel: 24,
                    bytesPerRow: Int(result.width) * 3, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: [], provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            }
        }
        guard let image else { return nil }
        guard let oriented = try? ImageOrientation.normalized(image, orientation: result.orientation) else { return nil }
        return ImageOrientation.resized(oriented, maxPixelSize: maxPixelSize)
    }
}
