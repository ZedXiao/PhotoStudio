import SwiftUI
import PhotoStudioCore

struct GeneralSettingsView: View {
    @AppStorage("showFilmstrip") private var showFilmstrip = true
    @AppStorage("showCameraMetadata") private var showCameraMetadata = true
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Form {
            Section("浏览") {
                Toggle("显示底部缩略图栏", isOn: $showFilmstrip)
                Toggle("显示相机与拍摄参数", isOn: $showCameraMetadata)
            }
            Section("RAW 预览") {
                LabeledContent("主预览", value: "始终完整解码 RAW")
                LabeledContent("解码器", value: "Apple RAW + LibRaw \(StandardPhotoDecoder.libRawVersion)")
                Text("RAW 与子文件夹开关分别保存在各自文件夹中。").font(.caption).foregroundStyle(.secondary)
                Button("查看相机兼容情况…") { openWindow(id: "compatibility") }
            }
            Section("文件管理") {
                Text("删除前会确认，配套 RAW 需手动勾选。文件会移到系统废纸篓。")
                    .font(.callout).foregroundStyle(.secondary)
                Text("照片按原位置读取；JPEG 与 RAW 仅按同目录、同主文件名配对。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped).padding().frame(width: 510, height: 400)
    }
}
