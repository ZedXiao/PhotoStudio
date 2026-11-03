import Foundation

/// A gesture may contain hundreds of scroll and momentum events, but produces at most one selection.
public struct PhotoSwipeTracker {
    public enum Phase { case began, changed, ended, cancelled }
    private var horizontal = 0.0
    private var vertical = 0.0
    private var active = false
    private var consumed = false
    private var verticalLocked = false
    public init() {}

    public mutating func consume(dx: Double, dy: Double, phase: Phase, momentum: Bool = false) -> Int? {
        // Inertia must never start a gesture or trigger a second photo, including after view recreation.
        guard !momentum else { return nil }
        if phase == .began { reset(); active = true }
        guard active else { return nil }
        if phase == .cancelled { reset(); return nil }
        horizontal += dx; vertical += dy
        if abs(vertical) >= 12, abs(vertical) > abs(horizontal) * 1.4 { verticalLocked = true }
        var result: Int?
        if !consumed, !verticalLocked, abs(horizontal) >= 40, abs(horizontal) > abs(vertical) * 1.4 {
            consumed = true
            result = horizontal < 0 ? 1 : -1
        }
        if phase == .ended { active = false }
        return result
    }
    public mutating func reset() { horizontal = 0; vertical = 0; active = false; consumed = false; verticalLocked = false }
}
