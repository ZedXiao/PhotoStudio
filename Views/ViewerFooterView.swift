import SwiftUI

struct ViewerFooterView: View {
    let browser: BrowserStore
    let showFilmstrip: Bool
    @AppStorage("showCameraMetadata") private var showCameraMetadata = true

    var body: some View {
        VStack(spacing: 0) {
            if !browser.visible.isEmpty, showFilmstrip {
                FilmstripView(browser: browser)
                Divider().padding(.horizontal, 16)
            }
            HStack(spacing: 12) {
                if let photo = browser.photo {
                    Text("\(photo.image.width) × \(photo.image.height)").monospacedDigit()
                    if showCameraMetadata {
                        if !photo.metadata.camera.isEmpty { Text(photo.metadata.camera).lineLimit(1) }
                        if !photo.metadata.exposureDescription.isEmpty { Text(photo.metadata.exposureDescription).lineLimit(1) }
                    }
                    Spacer(minLength: 5)
                    if browser.selectedAsset?.isRaw == true {
                        Label(photo.engine, systemImage: "checkmark.circle").lineLimit(1)
                    }
                    if let asset = browser.selectedAsset {
                        Text(ByteCountFormatter.string(fromByteCount: asset.byteSize, countStyle: .file))
                    }
                } else {
                    Image(systemName: "photo.stack")
                    Text("\(browser.visible.count) 张照片")
                    Spacer()
                    if browser.isScanning { ProgressView().controlSize(.mini) }
                }
                if !browser.snapshot.warnings.isEmpty {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
                        .help(browser.snapshot.warnings.joined(separator: "\n"))
                }
            }
            .font(.system(size: 10)).foregroundStyle(.secondary)
            .padding(.horizontal, 17).frame(height: 32)
        }
    }
}
