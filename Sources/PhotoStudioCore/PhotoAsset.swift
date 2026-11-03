import Foundation
import UniformTypeIdentifiers

public enum PhotoFormats {
    public static let rawExtensions: Set<String> = [
        "3fr", "ari", "arw", "bay", "cap", "cr2", "cr3", "crw", "dcr", "dcs", "dng", "drf",
        "eip", "erf", "fff", "gpr", "iiq", "k25", "kdc", "mdc", "mef", "mos", "mrw", "nef",
        "nrw", "obm", "orf", "pef", "ptx", "pxn", "r3d", "raf", "raw", "rwl", "rw2", "rwz",
        "sr2", "srf", "srw", "sti", "x3f"
    ]
    public static let imageExtensions: Set<String> = ["jpg", "jpeg", "jpe", "heic", "heif", "png", "tif", "tiff", "bmp", "gif", "webp", "avif", "jxl"]
    public static func isRaw(_ url: URL) -> Bool {
        rawExtensions.contains(url.pathExtension.lowercased()) ||
        UTType(filenameExtension: url.pathExtension)?.conforms(to: .rawImage) == true
    }
    public static func isSupported(_ url: URL) -> Bool {
        isRaw(url) || imageExtensions.contains(url.pathExtension.lowercased())
    }
}

public struct PhotoAsset: Identifiable, Hashable, Sendable {
    public let url: URL
    public let isRaw: Bool
    public let byteSize: Int64
    public let modifiedAt: Date
    public var id: URL { url }
    public var name: String { url.lastPathComponent }
    public var format: String { url.pathExtension.uppercased() }
    public var stem: String { url.deletingPathExtension().lastPathComponent }
    public var cacheKey: String { "\(url.path)|\(modifiedAt.timeIntervalSince1970)|\(byteSize)" }

    public init(url: URL, byteSize: Int64 = 0, modifiedAt: Date = .distantPast) {
        self.url = url.standardizedFileURL
        self.isRaw = PhotoFormats.isRaw(url)
        self.byteSize = byteSize
        self.modifiedAt = modifiedAt
    }
}

public struct FolderSnapshot: Sendable {
    public let assets: [PhotoAsset]
    public let warnings: [String]
    public let subdirectories: [URL]
    public init(assets: [PhotoAsset], warnings: [String] = [], subdirectories: [URL] = []) {
        self.assets = assets; self.warnings = warnings; self.subdirectories = subdirectories
    }
    public func visible(includeRaw: Bool) -> [PhotoAsset] {
        includeRaw ? assets : assets.filter { !$0.isRaw }
    }
}

public enum PhotoSelection {
    public static func afterRemoving(_ removed: Set<URL>, from assets: [PhotoAsset], selected: URL?) -> URL? {
        let remaining = assets.filter { !removed.contains($0.id) }
        if let selected, remaining.contains(where: { $0.id == selected }) { return selected }
        let oldIndex = assets.firstIndex { $0.id == selected } ?? 0
        return remaining.isEmpty ? nil : remaining[min(oldIndex, remaining.count - 1)].id
    }
}
