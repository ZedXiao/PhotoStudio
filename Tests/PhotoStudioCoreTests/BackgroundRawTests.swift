import XCTest
@testable import PhotoStudioCore

final class BackgroundRawTests: XCTestCase {
    func testEveryRawBridgeEntryPointFitsIn512KiBWorkerStack() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PhotoStudioInvalid-\(UUID()).arw")
        try Data("Invalid RAW for worker-stack regression".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let complete = expectation(description: "RAW bridge returns from a 512 KiB thread")
        let thread = Thread {
            autoreleasepool {
                // The previous implementation crashed before even checking the input file.
                XCTAssertEqual(StandardPhotoDecoder.rawOrientation(url), 0)
                do {
                    _ = try StandardPhotoDecoder().decodeWithLibRaw(PhotoAsset(url: url))
                    XCTFail("Invalid RAW must report an error")
                } catch { /* Expected decoding error, without overflowing the worker stack. */ }
                XCTAssertNil(ThumbnailDecoder.decode(PhotoAsset(url: url)))
                complete.fulfill()
            }
        }
        thread.name = "PhotoStudio.StackRegression"
        thread.stackSize = 512 * 1024
        thread.start()
        wait(for: [complete], timeout: 10)
    }
}
