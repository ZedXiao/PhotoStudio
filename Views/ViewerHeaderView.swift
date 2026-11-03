import SwiftUI

struct ViewerHeaderView: View {
    let browser: BrowserStore

    var body: some View {
        HStack(spacing: 10) {
            if let asset = browser.selectedAsset {
                Text(asset.isRaw ? "RAW" : asset.format)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .foregroundStyle(asset.isRaw ? Color.orange : .secondary)
                    .background(.quaternary, in: Capsule())
                Text(asset.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1).truncationMode(.middle).textSelection(.enabled)
            } else {
                Image(systemName: "photo.on.rectangle").foregroundStyle(.secondary)
                Text(browser.directoryName ?? "").font(.system(size: 13, weight: .medium))
            }
            Spacer(minLength: 12)
            Toggle("包含 RAW", isOn: Binding(get: { browser.includeRaw }, set: browser.setIncludeRaw))
                .toggleStyle(.switch).controlSize(.small)
                .help("将当前文件夹内的 RAW 文件作为独立照片加入浏览")
                .accessibilityIdentifier("includeRAW")
        }
        .disabled(browser.isDeleting)
        .padding(.horizontal, 17).frame(height: 48)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}
