import SwiftUI

struct WelcomeView: View {
    let browser: BrowserStore
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 52, weight: .ultraLight))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 112, height: 104)
                    .glassEffect(.regular, in: .rect(cornerRadius: 28))
            }
            .frame(width: 170, height: 130)
            Text("从一个文件夹开始").font(.system(size: 25, weight: .semibold)).padding(.top, 12)
            Text("浏览拍摄原片，放大检查细节，留下值得保留的瞬间。")
                .font(.system(size: 13)).foregroundStyle(.secondary).padding(.top, 10)
            HStack(spacing: 12) {
                Button("添加文件夹…", action: browser.addFolders).buttonStyle(.glassProminent)
                Button("打开照片…", action: browser.openImage).buttonStyle(.glass)
            }
            .buttonBorderShape(.capsule).controlSize(.large).padding(.top, 26)
            Label("也可以将照片或文件夹拖到这里", systemImage: "arrow.down.doc")
                .font(.system(size: 11)).foregroundStyle(.tertiary).padding(.top, 21)
            HStack(spacing: 16) {
                Text("JPEG / HEIC / TIFF")
                Text("RAW 原图解码")
                Text("本地文件管理")
            }
            .font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary).padding(.top, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
