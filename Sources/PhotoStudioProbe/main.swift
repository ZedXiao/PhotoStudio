import Foundation
import PhotoStudioCore
import ImageIO
import CoreImage

let args = Array(CommandLine.arguments.dropFirst())
let forceLibRaw = args.contains("--libraw")
let paths = args.filter { !$0.hasPrefix("--") }
let decoder = StandardPhotoDecoder()
var failed = false
func process(_ path: String) {
    autoreleasepool {
        let start = Date()
        let url = URL(fileURLWithPath: path)
        var record: [String: Any] = ["file": url.lastPathComponent, "path": url.path, "backgroundWorker": !Thread.isMainThread]
        do {
            let asset = PhotoAsset(url: url)
            let photo = try forceLibRaw && asset.isRaw ? decoder.decodeWithLibRaw(asset) : decoder.decode(asset, cancellation: DecodeCancellation())
            record["status"] = "verified"
            record["camera"] = photo.metadata.camera
            record["format"] = asset.format
            record["engine"] = photo.engine
            record["width"] = photo.image.width; record["height"] = photo.image.height
            record["bits"] = photo.image.bitsPerComponent
            record["seconds"] = Date().timeIntervalSince(start)
            record["exposure"] = photo.metadata.exposureDescription
            let thumbnail = ThumbnailDecoder.decode(asset)
            record["thumbnail"] = thumbnail != nil
            if let thumbnail { record["thumbnailWidth"] = thumbnail.width; record["thumbnailHeight"] = thumbnail.height }
            if asset.isRaw { record["rawOrientation"] = StandardPhotoDecoder.rawOrientation(url) }
            var pixels = [UInt8](repeating: 0, count: 16 * 16 * 4)
            pixels.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 64,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(photo.image, in: CGRect(x: 0, y: 0, width: 16, height: 16))
            }
            record["sampleMean"] = Double(pixels.enumerated().filter { $0.offset % 4 != 3 }.reduce(0) { $0 + Int($1.element) }) / (256 * 3)
            if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
                record["sourceOrientation"] = props[kCGImagePropertyOrientation] as? NSNumber ?? 1
            }
            if let destinationDirectory = ProcessInfo.processInfo.environment["PHOTOSTUDIO_EXPORT_JPEG"] {
                let target = URL(fileURLWithPath: destinationDirectory).appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".jpg")
                guard let destination = CGImageDestinationCreateWithURL(target as CFURL, "public.jpeg" as CFString, 1, nil) else { throw PhotoDecodeError("Cannot create JPEG") }
                CGImageDestinationAddImage(destination, photo.image, [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary)
                guard CGImageDestinationFinalize(destination) else { throw PhotoDecodeError("Cannot write JPEG") }
            }
        } catch {
            failed = true
            record["status"] = "unsupported"
            record["error"] = error.localizedDescription
        }
        if let data = try? JSONSerialization.data(withJSONObject: record, options: [.sortedKeys]), let text = String(data: data, encoding: .utf8) { print(text) }
    }
}
for path in paths {
    if args.contains("--worker") {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        queue.addOperation { process(path) }
        queue.waitUntilAllOperationsAreFinished()
    } else { process(path) }
}
if paths.isEmpty {
    print("PhotoStudioProbe [--libraw] <photo> …\nLibRaw \(StandardPhotoDecoder.libRawVersion), \(StandardPhotoDecoder.libRawCameras.count) declared cameras")
}
exit(failed ? 1 : 0)
