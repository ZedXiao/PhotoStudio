import XCTest
@testable import PhotoStudioCore

final class BrowsingInteractionTests: XCTestCase {
    func testRawDeletionPreferenceSurvivesRecreationAndCanBeTurnedOff() throws {
        let suite = "PhotoStudio.preferences.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = BrowsingPreferences(defaults: defaults)
        XCTAssertFalse(first.deleteCompanionRaw)
        first.deleteCompanionRaw = true
        let restored = BrowsingPreferences(defaults: defaults)
        XCTAssertTrue(restored.deleteCompanionRaw)
        restored.deleteCompanionRaw = false
        XCTAssertFalse(BrowsingPreferences(defaults: defaults).deleteCompanionRaw)
    }
    func testEachDirectoryKeepsIndependentRawVisibilityAndExpansion() throws {
        let suite = "PhotoStudio.directories.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = BrowsingPreferences(defaults: defaults)
        preferences.directories = [
            "/trip": DirectoryPreferences(expanded: true),
            "/trip/day1": DirectoryPreferences(includeRaw: true, expanded: true),
            "/trip/day2": DirectoryPreferences()
        ]
        let restored = BrowsingPreferences(defaults: defaults).directories
        XCTAssertEqual(restored["/trip"], DirectoryPreferences(expanded: true))
        XCTAssertEqual(restored["/trip/day1"], DirectoryPreferences(includeRaw: true, expanded: true))
        XCTAssertEqual(restored["/trip/day2"], DirectoryPreferences())
    }
    func testLongSwipeAndItsMomentumAdvanceOnlyOnePhoto() {
        var tracker = PhotoSwipeTracker()
        var results: [Int] = []
        if let result = tracker.consume(dx: -10, dy: 0, phase: .began) { results.append(result) }
        for _ in 0..<100 {
            if let result = tracker.consume(dx: -10, dy: 0, phase: .changed) { results.append(result) }
        }
        _ = tracker.consume(dx: 0, dy: 0, phase: .ended)
        for _ in 0..<100 { XCTAssertNil(tracker.consume(dx: -10, dy: 0, phase: .changed, momentum: true)) }
        XCTAssertEqual(results, [1])
        // The next intentional gesture can immediately select another photo.
        XCTAssertEqual(tracker.consume(dx: 55, dy: 1, phase: .began), -1)
        XCTAssertNil(tracker.consume(dx: -150, dy: 0, phase: .changed))
    }
    func testMomentumCannotNavigateAfterCanvasRecreation() {
        var tracker = PhotoSwipeTracker()
        XCTAssertNil(tracker.consume(dx: -100, dy: 0, phase: .began, momentum: true))
        XCTAssertNil(tracker.consume(dx: -100, dy: 0, phase: .changed))
        XCTAssertEqual(tracker.consume(dx: -45, dy: 0, phase: .began), 1)
    }
    func testVerticalScrollSmallMotionAndCancelledGesturesDoNotNavigate() {
        var tracker = PhotoSwipeTracker()
        XCTAssertNil(tracker.consume(dx: 10, dy: 60, phase: .began))
        XCTAssertNil(tracker.consume(dx: 50, dy: 60, phase: .changed))
        XCTAssertNil(tracker.consume(dx: 500, dy: 0, phase: .changed))
        XCTAssertNil(tracker.consume(dx: 0, dy: 0, phase: .ended))
        XCTAssertNil(tracker.consume(dx: -15, dy: 0, phase: .began))
        XCTAssertNil(tracker.consume(dx: -10, dy: 0, phase: .ended))
        XCTAssertNil(tracker.consume(dx: -20, dy: 0, phase: .began))
        XCTAssertNil(tracker.consume(dx: -100, dy: 0, phase: .cancelled))
        XCTAssertNil(tracker.consume(dx: -100, dy: 0, phase: .changed))
    }
}
