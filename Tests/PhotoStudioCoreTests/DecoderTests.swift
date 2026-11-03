import XCTest
import CoreGraphics
import ImageIO
@testable import PhotoStudioCore

final class DecoderTests: XCTestCase {
    func testAllEXIFOrientationsMatchPixelLayout() throws {
        // A B / C D / E F: fixed expected layouts from the EXIF orientation definition.
        let bytes: [UInt8] = (0..<6).flatMap { [UInt8($0 * 40), 10, 20, 255] }
        let source = try XCTUnwrap(CGImage(width: 2, height: 3, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: 8, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue | CGBitmapInfo.byteOrder32Big.rawValue),
            provider: CGDataProvider(data: Data(bytes) as CFData)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
        let expected = [[0,1,2,3,4,5], [1,0,3,2,5,4], [5,4,3,2,1,0], [4,5,2,3,0,1],
                        [0,2,4,1,3,5], [4,2,0,5,3,1], [5,3,1,4,2,0], [1,3,5,0,2,4]]
        for orientation in 1...8 {
            let image = try ImageOrientation.normalized(source, orientation: Int32(orientation))
            let data = try XCTUnwrap(image.dataProvider?.data) as Data
            let labels = (0..<image.height).flatMap { row in
                (0..<image.width).map { column in Int((Double(data[row * image.bytesPerRow + column * 4]) / 40).rounded()) }
            }
            XCTAssertEqual(labels, expected[orientation - 1], "EXIF orientation \(orientation)")
        }
    }
    func testJPEGPortraitOrientationIsAppliedAndMetadataSurvives() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PhotoStudioPortrait-\(UUID()).jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        let image = try makeImage()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, "public.jpeg" as CFString, 1, nil))
        let properties: [CFString: Any] = [
            kCGImagePropertyOrientation: 6,
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFMake: "Test Camera", kCGImagePropertyTIFFModel: "Portrait"],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifFNumber: 2.8, kCGImagePropertyExifExposureTime: 0.002, kCGImagePropertyExifISOSpeedRatings: [400]]
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let result = try StandardPhotoDecoder().decode(PhotoAsset(url: url), cancellation: DecodeCancellation())
        XCTAssertEqual(result.image.width, 20)
        XCTAssertEqual(result.image.height, 30)
        XCTAssertEqual(result.metadata.camera, "Test Camera Portrait")
        XCTAssertEqual(result.metadata.iso, 400)
        XCTAssertEqual(result.metadata.aperture, 2.8)
        XCTAssertTrue(result.metadata.exposureDescription.contains("1/500"))
        let thumb = try XCTUnwrap(ThumbnailDecoder.decode(PhotoAsset(url: url)))
        XCTAssertLessThan(thumb.width, thumb.height)
    }
    func testPNGAndTIFFDecodeAtNativeSize() throws {
        for (ext, type) in [("png", "public.png"), ("tiff", "public.tiff")] {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("PhotoStudio-\(UUID()).\(ext)")
            defer { try? FileManager.default.removeItem(at: url) }
            let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, type as CFString, 1, nil))
            CGImageDestinationAddImage(destination, try makeImage(), nil)
            XCTAssertTrue(CGImageDestinationFinalize(destination))
            let result = try StandardPhotoDecoder().decode(PhotoAsset(url: url), cancellation: DecodeCancellation())
            XCTAssertEqual(result.image.width, 30); XCTAssertEqual(result.image.height, 20)
            XCTAssertEqual(result.engine, "ImageIO")
            XCTAssertNotNil(result.image.colorSpace)
        }
    }
    private func makeImage() throws -> CGImage {
        var bytes = [UInt8](repeating: 0, count: 30 * 20 * 4)
        for index in stride(from: 0, to: bytes.count, by: 4) {
            bytes[index] = UInt8((index / 4) % 30 * 8)
            bytes[index + 1] = 90; bytes[index + 2] = 140; bytes[index + 3] = 255
        }
        let data = Data(bytes) as CFData
        return try XCTUnwrap(CGImage(width: 30, height: 20, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: 120, space: CGColorSpace(name: CGColorSpace.displayP3)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: CGDataProvider(data: data)!, decode: nil, shouldInterpolate: true, intent: .defaultIntent))
    }
}
