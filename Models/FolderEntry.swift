import Foundation

struct FolderEntry: Codable, Identifiable, Hashable {
    var id: UUID
    var path: String
    var bookmark: Data?
    var includeRaw: Bool
    var recursive: Bool
    var url: URL { URL(fileURLWithPath: path, isDirectory: true) }
    var name: String { url.lastPathComponent }
    init(url: URL) {
        id = UUID(); path = url.standardizedFileURL.path
        includeRaw = false; recursive = false
        // Bookmark creation may block on removable volumes or system file access. The library
        // resolves it off the main thread after inserting the folder into the sidebar.
        bookmark = nil
    }
}
