import Foundation
import Observation
import PhotoStudioCore

struct CameraVerification: Codable, Identifiable {
    var id: String { "\(camera)|\(format)|\(mode)|\(engine)" }
    let camera: String
    let format: String
    let mode: String
    let engine: String
    let dimensions: String
    let source: String?
}

@MainActor @Observable
final class CompatibilityStore {
    static let shared = CompatibilityStore()
    private(set) var verified: [CameraVerification] = []
    private(set) var failedFiles: [String] = []
    let declared: [(camera: String, engines: String)]
    init() {
        var engines: [String: Set<String>] = [:]
        for camera in StandardPhotoDecoder.systemCameras { engines[camera, default: []].insert("Apple RAW") }
        for camera in StandardPhotoDecoder.libRawCameras { engines[camera, default: []].insert("LibRaw") }
        declared = engines.map { (camera: $0.key, engines: $0.value.sorted().joined(separator: " / ")) }
            .sorted { $0.camera.localizedStandardCompare($1.camera) == .orderedAscending }
        if let url = AppResources.bundle.url(forResource: "CameraValidation", withExtension: "json", subdirectory: "Resources"),
           let data = try? Data(contentsOf: url), let entries = try? JSONDecoder().decode([CameraVerification].self, from: data) { verified = entries }
    }
    func record(_ asset: PhotoAsset, photo: DecodedPhoto) {
        guard asset.isRaw else { return }
        let item = CameraVerification(camera: photo.metadata.camera.isEmpty ? asset.name : photo.metadata.camera,
            format: asset.format, mode: "本次打开的文件", engine: photo.engine,
            dimensions: "\(photo.image.width) × \(photo.image.height)", source: nil)
        if !verified.contains(where: { $0.id == item.id }) { verified.append(item) }
        failedFiles.removeAll { $0 == asset.name }
    }
    func recordFailure(_ asset: PhotoAsset) {
        guard asset.isRaw, !failedFiles.contains(asset.name) else { return }
        failedFiles.append(asset.name)
    }
}
