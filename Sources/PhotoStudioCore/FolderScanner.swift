import Foundation

public enum FolderScanner {
    public static func scan(_ root: URL, recursive: Bool = false,
                            cancelled: @Sendable () -> Bool = { false }) throws -> FolderSnapshot {
        let manager = FileManager.default
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isPackageKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey]
        // Read the directory first so an inaccessible root produces a useful error.
        let immediate = try manager.contentsOfDirectory(at: root, includingPropertiesForKeys: keys,
                                                        options: [.skipsHiddenFiles, .skipsPackageDescendants])
        var warnings: [String] = []
        var pending = [immediate]
        var assets: [PhotoAsset] = []
        var subdirectories: [URL] = []
        while let candidates = pending.popLast() {
            if cancelled() { throw CancellationError() }
            for url in candidates {
                if cancelled() { throw CancellationError() }
                do {
                    let info = try url.resourceValues(forKeys: Set(keys))
                    guard info.isSymbolicLink != true else { continue }
                    if info.isDirectory == true {
                        if info.isPackage != true, url.deletingLastPathComponent().standardizedFileURL.path == root.standardizedFileURL.path {
                            subdirectories.append(url.standardizedFileURL)
                        }
                        if recursive, info.isPackage != true {
                            pending.append(try manager.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]))
                        }
                    } else if info.isRegularFile == true, PhotoFormats.isSupported(url) {
                        assets.append(PhotoAsset(url: url, byteSize: Int64(info.fileSize ?? 0), modifiedAt: info.contentModificationDate ?? .distantPast))
                    }
                } catch { warnings.append("\(url.lastPathComponent)：\(error.localizedDescription)") }
            }
        }
        assets.sort { lhs, rhs in
            let order = lhs.stem.localizedStandardCompare(rhs.stem)
            if order != .orderedSame { return order == .orderedAscending }
            if lhs.url.deletingLastPathComponent() == rhs.url.deletingLastPathComponent(), lhs.isRaw != rhs.isRaw { return !lhs.isRaw }
            return lhs.url.path.localizedStandardCompare(rhs.url.path) == .orderedAscending
        }
        subdirectories.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        return FolderSnapshot(assets: assets, warnings: warnings, subdirectories: subdirectories)
    }

    /// Only enumerate the next level. Opening a branch never merges its photos with its parent.
    public static func subdirectories(of root: URL) throws -> [URL] {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey]
        return try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles])
            .filter {
                let info = try $0.resourceValues(forKeys: keys)
                return info.isDirectory == true && info.isPackage != true && info.isSymbolicLink != true
            }
            .map(\.standardizedFileURL)
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
}
