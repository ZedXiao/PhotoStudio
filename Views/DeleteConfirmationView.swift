import SwiftUI
import PhotoStudioCore

struct DeleteConfirmationView: View {
    let plan: DeletePlan
    let browser: BrowserStore
    @FocusState private var panelFocused: Bool
    private var includeRaw: Binding<Bool> {
        Binding(get: { !plan.companions.isEmpty && browser.library.deleteCompanionRaw },
                set: { browser.library.deleteCompanionRaw = $0 })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 15) {
                Image(systemName: "trash").font(.system(size: 27, weight: .light))
                    .foregroundStyle(.secondary).frame(width: 45, height: 45)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 6) {
                    Text("将这张照片移到废纸篓？").font(.system(size: 16, weight: .semibold))
                    Text(plan.primary.name).font(.system(size: 12, design: .monospaced)).textSelection(.enabled).lineLimit(3)
                    Text("之后可以从系统废纸篓找回。").font(.caption).foregroundStyle(.secondary)
                }
            }
            if !plan.primary.isRaw {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("同步删除对应 RAW 文件\(plan.companions.count > 1 ? "（\(plan.companions.count) 个）" : "")", isOn: includeRaw)
                        .disabled(plan.companions.isEmpty || browser.isDeleting)
                        .accessibilityIdentifier("deleteCompanionRAW")
                    if plan.companions.isEmpty {
                        Text("当前目录中未找到同名 RAW 文件。").font(.caption).foregroundStyle(.secondary).padding(.leading, 20)
                    } else {
                        Group {
                            if plan.companions.count > 4 {
                                ScrollView { companionFiles }.frame(height: 120)
                            } else {
                                companionFiles
                            }
                        }.padding(.leading, 20)
                    }
                }
            }
            HStack {
                if browser.isDeleting { ProgressView().controlSize(.small); Text("正在移动…").font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Button("取消", action: cancel)
                    .buttonStyle(.glass).keyboardShortcut(.cancelAction).disabled(browser.isDeleting)
                Button("移到废纸篓", role: .destructive) { browser.performDelete(plan, includeRaw: includeRaw.wrappedValue) }
                    .keyboardShortcut(.defaultAction).buttonStyle(.glassProminent).tint(.red)
                    .disabled(browser.isDeleting || browser.deletePlan?.id != plan.id).accessibilityIdentifier("confirmTrash")
            }.padding(.top, 3)
        }
        .padding(28).frame(width: 480)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("删除照片确认")
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("deleteConfirmation")
        .focusable().focusEffectDisabled().focused($panelFocused)
        .onKeyPress(.escape) { cancel(); return .handled }
        .onKeyPress(.return) {
            if !browser.isDeleting { browser.performDelete(plan, includeRaw: includeRaw.wrappedValue) }
            return .handled
        }
        .onAppear { panelFocused = true }
    }
    private func cancel() {
        guard !browser.isDeleting, browser.deletePlan?.id == plan.id else { return }
        browser.deletePlan = nil
    }
    private var companionFiles: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(plan.companions) { asset in
                Label(asset.name, systemImage: "doc").font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary).lineLimit(2)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
