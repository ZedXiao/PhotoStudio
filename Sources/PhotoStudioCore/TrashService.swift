import Foundation

public struct DeletePlan: Identifiable, Sendable {
    public let id = UUID()
    public let primary: PhotoAsset
    public let companions: [PhotoAsset]
    public init(primary: PhotoAsset, allAssets: [PhotoAsset]) {
        self.primary = primary
        self.companions = primary.isRaw ? [] : allAssets.filter {
            $0.isRaw && $0.stem == primary.stem &&
            $0.url.deletingLastPathComponent() == primary.url.deletingLastPathComponent()
        }
    }
    public func targets(includeRaw: Bool) -> [PhotoAsset] {
        [primary] + (includeRaw ? companions : [])
    }
}

public struct TrashFailure: Sendable {
    public let name: String
    public let reason: String
}
public struct TrashResult: Sendable {
    public var trashed: Set<URL> = []
    public var failures: [TrashFailure] = []
}
public enum TrashService {
    public static func execute(_ plan: DeletePlan, includeRaw: Bool,
                               trash: (URL) throws -> Void = { url in
                                   _ = try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                               }) -> TrashResult {
        var result = TrashResult()
        for asset in plan.targets(includeRaw: includeRaw) {
            do {
                // Do not replace permanent deletion for volumes that cannot use Trash.
                try trash(asset.url)
                result.trashed.insert(asset.id)
            } catch {
                result.failures.append(TrashFailure(name: asset.name, reason: error.localizedDescription))
            }
        }
        return result
    }
}
