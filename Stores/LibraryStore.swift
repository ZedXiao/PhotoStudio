import Foundation
import Observation
import PhotoStudioCore

@MainActor @Observable
final class LibraryStore {
    static let shared = LibraryStore()
    private(set) var folders: [FolderEntry] = []
    private var accessibleURLs: [UUID: URL] = [:]
    @ObservationIgnored let defaults: UserDefaults
    @ObservationIgnored private let preferences: BrowsingPreferences
    private(set) var directoryPreferences: [String: DirectoryPreferences]
    var deleteCompanionRaw: Bool { didSet { preferences.deleteCompanionRaw = deleteCompanionRaw } }
    var lastDirectoryPath: String? {
        get { defaults.string(forKey: "lastDirectoryPath") }
        set { defaults.set(newValue, forKey: "lastDirectoryPath") }
    }
    var lastFolderID: UUID? {
        get { defaults.string(forKey: "lastFolderID").flatMap(UUID.init(uuidString:)) }
        set { defaults.set(newValue?.uuidString, forKey: "lastFolderID") }
    }
    init() {
        defaults = ProcessInfo.processInfo.arguments.contains("--isolated")
            ? UserDefaults(suiteName: "app.photostudio.qa")! : .standard
        preferences = BrowsingPreferences(defaults: defaults)
        directoryPreferences = preferences.directories
        deleteCompanionRaw = preferences.deleteCompanionRaw
        if let data = defaults.data(forKey: "folders.v1"), let saved = try? JSONDecoder().decode([FolderEntry].self, from: data) {
            folders = saved
        }
        for saved in folders {
            resolveAccess(saved)
            guard let folder = folder(saved.id) else { continue }
            if directoryPreferences[folder.path] == nil {
                directoryPreferences[folder.path] = DirectoryPreferences(includeRaw: folder.includeRaw, expanded: folder.recursive)
            }
        }
        preferences.directories = directoryPreferences
    }
    @discardableResult func add(_ url: URL) -> FolderEntry {
        let normalized = url.standardizedFileURL.resolvingSymlinksInPath()
        if let existing = folders.first(where: { $0.path == normalized.path }) { return existing }
        let folder = FolderEntry(url: normalized)
        folders.append(folder); resolveAccess(folder)
        if directoryPreferences[folder.path] == nil { setExpanded(true, for: normalized) }
        save(); cacheBookmark(for: folder, url: normalized)
        return folder
    }
    func update(_ id: UUID, includeRaw: Bool? = nil, recursive: Bool? = nil) {
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        if let includeRaw { folders[index].includeRaw = includeRaw }
        if let recursive { folders[index].recursive = recursive }
        save()
    }
    func replace(_ id: UUID, with url: URL) {
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        migrateSettings(from: folders[index].url, to: url)
        if let old = accessibleURLs.removeValue(forKey: id) { old.stopAccessingSecurityScopedResource() }
        var replacement = FolderEntry(url: url)
        replacement.id = id; replacement.includeRaw = folders[index].includeRaw; replacement.recursive = folders[index].recursive
        folders[index] = replacement; resolveAccess(replacement); save()
        cacheBookmark(for: replacement, url: url)
    }
    func remove(_ id: UUID) {
        folders.removeAll { $0.id == id }
        if let url = accessibleURLs.removeValue(forKey: id) { url.stopAccessingSecurityScopedResource() }
        save()
    }
    func folder(_ id: UUID?) -> FolderEntry? { folders.first { $0.id == id } }
    func settings(for url: URL) -> DirectoryPreferences { directoryPreferences[url.standardizedFileURL.path] ?? DirectoryPreferences() }
    func setIncludeRaw(_ value: Bool, for url: URL) {
        var settings = settings(for: url); settings.includeRaw = value
        directoryPreferences[url.standardizedFileURL.path] = settings
        preferences.directories = directoryPreferences
        if let root = folders.first(where: { $0.url.standardizedFileURL == url.standardizedFileURL }) { update(root.id, includeRaw: value) }
    }
    func setExpanded(_ value: Bool, for url: URL) {
        var settings = settings(for: url); settings.expanded = value
        directoryPreferences[url.standardizedFileURL.path] = settings
        preferences.directories = directoryPreferences
    }
    func root(containing url: URL) -> FolderEntry? {
        // Prefer the nearest saved ancestor. Path components avoid mistaking /trip2 for a child of /trip.
        folders.filter { url.standardizedFileURL.pathComponents.starts(with: $0.url.standardizedFileURL.pathComponents) }
            .max { $0.path.count < $1.path.count }
    }
    private func resolveAccess(_ folder: FolderEntry) {
        var stale = false
        let url = folder.bookmark.flatMap { try? URL(resolvingBookmarkData: $0, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale) } ?? folder.url
        if url.startAccessingSecurityScopedResource() { accessibleURLs[folder.id] = url }
        if url.path != folder.path || stale, let index = folders.firstIndex(where: { $0.id == folder.id }) {
            migrateSettings(from: folder.url, to: url)
            var updated = FolderEntry(url: url)
            updated.id = folder.id; updated.includeRaw = folder.includeRaw; updated.recursive = folder.recursive
            updated.bookmark = folder.bookmark
            folders[index] = updated; save()
            cacheBookmark(for: updated, url: url)
        }
    }
    private func cacheBookmark(for folder: FolderEntry, url: URL) {
        Task { [weak self] in
            let bookmark = await Task.detached(priority: .utility) {
                (try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil))
                    ?? (try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil))
            }.value
            guard let self, let bookmark,
                  let index = self.folders.firstIndex(where: { $0.id == folder.id && $0.path == folder.path }) else { return }
            self.folders[index].bookmark = bookmark; self.save()
        }
    }
    private func migrateSettings(from old: URL, to new: URL) {
        guard old.path != new.path else { return }
        for (path, settings) in directoryPreferences {
            guard URL(fileURLWithPath: path).pathComponents.starts(with: old.pathComponents) else { continue }
            directoryPreferences[new.path + path.dropFirst(old.path.count)] = settings
        }
        preferences.directories = directoryPreferences
    }
    private func save() {
        if let data = try? JSONEncoder().encode(folders) { defaults.set(data, forKey: "folders.v1") }
    }
}
