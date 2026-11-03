import Foundation

struct FolderLocation: Hashable {
    let rootID: UUID
    let url: URL
    init(rootID: UUID, url: URL) {
        self.rootID = rootID; self.url = url.standardizedFileURL
    }
}
