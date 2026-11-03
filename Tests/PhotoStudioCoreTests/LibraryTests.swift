import XCTest
@testable import PhotoStudioCore

final class LibraryTests: XCTestCase {
    private var root: URL!
    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("PhotoStudioTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: root) }
    @discardableResult private func file(_ path: String) throws -> URL {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data([0x42]).write(to: url)
        return url
    }
    func testScanKeepsHiddenRawInIndexAndUsesNaturalOrder() throws {
        try ["IMG_10.JPG", "IMG_2.jpg", "IMG_2.ARW", "notes.txt", ".hidden.jpg", "nested/IMG_1.NEF"].forEach { try file($0) }
        let snapshot = try FolderScanner.scan(root)
        XCTAssertEqual(snapshot.assets.map(\.name), ["IMG_2.jpg", "IMG_2.ARW", "IMG_10.JPG"])
        XCTAssertEqual(snapshot.visible(includeRaw: false).count, 2)
        XCTAssertEqual(DeletePlan(primary: snapshot.assets[0], allAssets: snapshot.assets).companions.map(\.name), ["IMG_2.ARW"])
    }
    func testRecursiveScanDoesNotTraverseSymlinksOrHiddenFolders() throws {
        try file("first.jpg"); try file("nested/second.raf"); try file(".hidden/third.jpg")
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("loop"), withDestinationURL: root)
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("alias.jpg"), withDestinationURL: root.appendingPathComponent("first.jpg"))
        let snapshot = try FolderScanner.scan(root, recursive: true)
        XCTAssertEqual(Set(snapshot.assets.map(\.name)), ["first.jpg", "second.raf"])
    }
    func testDirectoryBrowsingKeepsEachLevelSeparateAndListsNaturalOrder() throws {
        try ["root.jpg", "trip10/IMG_1.JPG", "trip2/IMG_1.JPG", "trip2/IMG_1.ARW", "trip2/day1/portrait.jpg", ".hidden/a.jpg", "Photos.app/internal.jpg"].forEach { try file($0) }
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("loop"), withDestinationURL: root)
        let parent = try FolderScanner.scan(root)
        XCTAssertEqual(parent.assets.map(\.name), ["root.jpg"])
        XCTAssertEqual(parent.subdirectories.map(\.lastPathComponent), ["trip2", "trip10"])
        XCTAssertEqual(try FolderScanner.subdirectories(of: root).map(\.lastPathComponent), ["trip2", "trip10"])
        let trip = try FolderScanner.scan(root.appendingPathComponent("trip2"))
        XCTAssertEqual(trip.visible(includeRaw: false).map(\.name), ["IMG_1.JPG"])
        XCTAssertEqual(trip.subdirectories.map(\.lastPathComponent), ["day1"])
        XCTAssertEqual(DeletePlan(primary: trip.assets[0], allAssets: trip.assets).companions.map(\.name), ["IMG_1.ARW"])
        let day = try FolderScanner.scan(trip.subdirectories[0])
        XCTAssertEqual(day.assets.map(\.name), ["portrait.jpg"])
    }
    func testPairingRequiresSameDirectoryAndExactStem() throws {
        let names = ["DSC_1.jpg", "DSC_1.ARW", "DSC_1.nef", "DSC_10.raf", "elsewhere/DSC_1.ARW"]
        let photos = try names.map { PhotoAsset(url: try file($0)) }
        let plan = DeletePlan(primary: photos[0], allAssets: photos)
        XCTAssertEqual(plan.companions.map(\.name), ["DSC_1.ARW", "DSC_1.nef"])
        XCTAssertEqual(plan.targets(includeRaw: false).count, 1)
        XCTAssertEqual(plan.targets(includeRaw: true).count, 3)
        XCTAssertTrue(DeletePlan(primary: photos[1], allAssets: photos).companions.isEmpty)
    }
    func testTrashFailureReportsOnlySuccessfulFilesAsRemoved() throws {
        let assets = try ["A.jpg", "A.ARW", "A.NEF"].map { PhotoAsset(url: try file($0)) }
        let plan = DeletePlan(primary: assets[0], allAssets: assets)
        var attempted: [URL] = []
        let result = TrashService.execute(plan, includeRaw: true) { url in
            attempted.append(url)
            if url.pathExtension == "ARW" { throw CocoaError(.fileWriteNoPermission) }
        }
        XCTAssertEqual(attempted.count, 3)
        XCTAssertEqual(result.trashed, [assets[0].id, assets[2].id])
        XCTAssertEqual(result.failures.map(\.name), ["A.ARW"])
        var jpegOnly: [URL] = []
        _ = TrashService.execute(plan, includeRaw: false) { jpegOnly.append($0) }
        XCTAssertEqual(jpegOnly, [assets[0].id])
    }
    func testSelectionAfterDeletingMiddleLastAndAll() throws {
        let assets = try ["1.jpg", "2.jpg", "3.jpg"].map { PhotoAsset(url: try file($0)) }
        XCTAssertEqual(PhotoSelection.afterRemoving([assets[1].id], from: assets, selected: assets[1].id), assets[2].id)
        XCTAssertEqual(PhotoSelection.afterRemoving([assets[2].id], from: assets, selected: assets[2].id), assets[1].id)
        XCTAssertNil(PhotoSelection.afterRemoving(Set(assets.map(\.id)), from: assets, selected: assets[0].id))
        XCTAssertEqual(PhotoSelection.afterRemoving([assets[2].id], from: assets, selected: assets[0].id), assets[0].id)
    }
    func testCancelledScanAndDecodeNeverReturnAnImage() throws {
        try file("A.jpg")
        XCTAssertThrowsError(try FolderScanner.scan(root, cancelled: { true })) { XCTAssertTrue($0 is CancellationError) }
        let cancellation = DecodeCancellation(); cancellation.cancel()
        XCTAssertThrowsError(try StandardPhotoDecoder().decode(PhotoAsset(url: root.appendingPathComponent("A.jpg")), cancellation: cancellation)) {
            XCTAssertTrue($0 is CancellationError)
        }
    }
    func testCorruptAndMissingPhotosFailCleanly() throws {
        let decoder = StandardPhotoDecoder()
        for name in ["broken.jpg", "broken.CR3", "broken.RAF", "broken.NEF", "missing.ARW"] {
            if !name.hasPrefix("missing") { try file(name) }
            XCTAssertThrowsError(try decoder.decode(PhotoAsset(url: root.appendingPathComponent(name)), cancellation: DecodeCancellation()))
        }
    }
    func testRawLibraryIsBundledAndDeclaresMajorBrands() {
        XCTAssertTrue(StandardPhotoDecoder.libRawVersion.hasPrefix("0.22.3"))
        let cameras = StandardPhotoDecoder.libRawCameras.joined(separator: "\n").lowercased()
        for brand in ["canon", "nikon", "sony", "fujifilm", "panasonic", "olympus", "pentax", "leica", "hasselblad"] {
            XCTAssertTrue(cameras.contains(brand), brand)
        }
    }
}
