import Foundation
import AppKit
import PhotoStudioCore

final class ImagePipeline: @unchecked Sendable {
    static let shared = ImagePipeline()
    private final class PhotoBox: NSObject {
        let photo: DecodedPhoto
        init(_ photo: DecodedPhoto) { self.photo = photo }
    }
    private final class ThumbnailBox: NSObject {
        let image: CGImage
        init(_ image: CGImage) { self.image = image }
    }
    private let decoder = StandardPhotoDecoder()
    private let photos = NSCache<NSString, PhotoBox>()
    private let thumbnails = NSCache<NSString, ThumbnailBox>()
    private let fullQueue = OperationQueue()
    private let thumbnailQueue = OperationQueue()
    let cacheBudget = min(512 * 1024 * 1024, Int(ProcessInfo.processInfo.physicalMemory / 8))

    private init() {
        photos.totalCostLimit = cacheBudget
        thumbnails.totalCostLimit = 64 * 1024 * 1024
        fullQueue.name = "PhotoStudio.FullImage"; fullQueue.maxConcurrentOperationCount = 1
        fullQueue.qualityOfService = .userInitiated
        thumbnailQueue.name = "PhotoStudio.Thumbnails"; thumbnailQueue.maxConcurrentOperationCount = 2
        thumbnailQueue.qualityOfService = .utility
    }
    func load(_ asset: PhotoAsset, cancellation: DecodeCancellation, prefetch: Bool = false) async throws -> DecodedPhoto {
        if let cached = photos.object(forKey: asset.cacheKey as NSString) { try cancellation.check(); return cached.photo }
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                let operation = BlockOperation { [self] in
                    autoreleasepool {
                        do {
                            try cancellation.check()
                            if let cached = photos.object(forKey: asset.cacheKey as NSString) {
                                continuation.resume(returning: cached.photo); return
                            }
                            let photo = try decoder.decode(asset, cancellation: cancellation)
                            try cancellation.check()
                            if photo.byteCost <= cacheBudget { photos.setObject(PhotoBox(photo), forKey: asset.cacheKey as NSString, cost: photo.byteCost) }
                            continuation.resume(returning: photo)
                        } catch { continuation.resume(throwing: error) }
                    }
                }
                operation.queuePriority = prefetch ? .veryLow : .veryHigh
                fullQueue.addOperation(operation)
            }
        }, onCancel: { cancellation.cancel() })
    }
    func thumbnail(_ asset: PhotoAsset) async -> CGImage? {
        if let box = thumbnails.object(forKey: asset.cacheKey as NSString) { return box.image }
        let token = DecodeCancellation()
        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { continuation in
                thumbnailQueue.addOperation { [self] in
                    autoreleasepool {
                        guard !token.isCancelled else { continuation.resume(returning: nil); return }
                        let image = ThumbnailDecoder.decode(asset, maxPixelSize: 512)
                        if let image, !token.isCancelled {
                            thumbnails.setObject(ThumbnailBox(image), forKey: asset.cacheKey as NSString, cost: image.bytesPerRow * image.height)
                        }
                        continuation.resume(returning: token.isCancelled ? nil : image)
                    }
                }
            }
        }, onCancel: { token.cancel() })
    }
    func invalidate(_ assets: [PhotoAsset]) {
        for asset in assets {
            photos.removeObject(forKey: asset.cacheKey as NSString)
            thumbnails.removeObject(forKey: asset.cacheKey as NSString)
        }
    }
    func clear() { photos.removeAllObjects(); thumbnails.removeAllObjects() }
}
