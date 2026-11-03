import SwiftUI
import PhotoStudioCore

struct CameraSupportView: View {
    @State private var store = CompatibilityStore.shared
    @State private var search = ""
    @State private var tab = 0
    private var verified: [CameraVerification] {
        store.verified.filter { search.isEmpty || "\($0.camera) \($0.format) \($0.mode)".localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                Image(systemName: "camera.aperture").font(.system(size: 32, weight: .light)).foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 5) {
                    Text("RAW 相机兼容").font(.title2.weight(.semibold))
                    Text("Apple 系统解码与 LibRaw \(StandardPhotoDecoder.libRawVersion) 互补处理。")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
            }
            Text("同一型号的不同压缩方式可能有不同结果。“已验证”仅对应列出的样片或本次实际打开的文件。")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Picker("查看", selection: $tab) {
                    Text("已验证 \(store.verified.count)").tag(0)
                    Text("声明支持 \(store.declared.count)").tag(1)
                    Text("本次未能解码 \(store.failedFiles.count)").tag(2)
                }.pickerStyle(.segmented).labelsHidden()
                TextField("搜索相机或格式", text: $search).textFieldStyle(.roundedBorder).frame(width: 190)
            }
            Group {
                if tab == 0 {
                    List(verified) { item in
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.camera).fontWeight(.medium)
                                Text("\(item.format) · \(item.mode)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(item.dimensions).font(.caption.monospacedDigit())
                                Text(item.engine).font(.caption2).foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 4)
                    }
                    .overlay { if verified.isEmpty { Text("打开 RAW 照片后，成功解码的记录会显示在这里。").foregroundStyle(.secondary).font(.callout) } }
                } else if tab == 1 {
                    List {
                        ForEach(Array(store.declared.filter { search.isEmpty || $0.camera.localizedCaseInsensitiveContains(search) }.enumerated()), id: \.offset) { _, item in
                            HStack { Text(item.camera); Spacer(); Text(item.engines).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                } else {
                    List(store.failedFiles.filter { search.isEmpty || $0.localizedCaseInsensitiveContains(search) }, id: \.self) { file in
                        Label(file, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary)
                    }
                    .overlay { if store.failedFiles.isEmpty { Label("本次尚无解码失败记录", systemImage: "checkmark.circle").foregroundStyle(.secondary) } }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Text("主预览始终使用 RAW 解码结果；底部缩略图可能来自文件内嵌预览。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24).frame(minWidth: 700, minHeight: 500)
    }
}
