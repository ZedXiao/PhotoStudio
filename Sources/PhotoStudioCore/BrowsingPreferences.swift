import Foundation

public struct DirectoryPreferences: Codable, Equatable, Sendable {
    public var includeRaw: Bool
    public var expanded: Bool
    public init(includeRaw: Bool = false, expanded: Bool = false) {
        self.includeRaw = includeRaw; self.expanded = expanded
    }
}

/// Separate persistence from window state so preferences can be verified without starting AppKit.
public final class BrowsingPreferences {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults) { self.defaults = defaults }
    public var deleteCompanionRaw: Bool {
        get { defaults.bool(forKey: "deleteCompanionRaw") }
        set { defaults.set(newValue, forKey: "deleteCompanionRaw") }
    }
    public var directories: [String: DirectoryPreferences] {
        get {
            guard let data = defaults.data(forKey: "directories.v1") else { return [:] }
            return (try? JSONDecoder().decode([String: DirectoryPreferences].self, from: data)) ?? [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) { defaults.set(data, forKey: "directories.v1") }
        }
    }
}
