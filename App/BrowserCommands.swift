import SwiftUI

private struct BrowserFocusKey: FocusedValueKey { typealias Value = BrowserStore }
extension FocusedValues {
    var photoBrowser: BrowserStore? {
        get { self[BrowserFocusKey.self] }
        set { self[BrowserFocusKey.self] = newValue }
    }
}

struct BrowserCommands: Commands {
    @FocusedValue(\.photoBrowser) private var browser
    @Environment(\.openWindow) private var openWindow
    @AppStorage("showFilmstrip") private var showFilmstrip = true
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("打开照片…") { browser?.openImage() }.keyboardShortcut("o").disabled(browser == nil || browser?.deletePlan != nil)
            Button("添加文件夹…") { browser?.addFolders() }.keyboardShortcut("o", modifiers: [.command, .shift]).disabled(browser == nil || browser?.deletePlan != nil)
            Divider()
            Button("刷新文件夹") { browser?.refresh() }.keyboardShortcut("r").disabled(browser?.folder == nil || browser?.deletePlan != nil)
        }
        CommandMenu("照片") {
            Button("上一张") { browser?.move(-1) }.keyboardShortcut(.leftArrow, modifiers: []).disabled(browser?.canPrevious != true || browser?.deletePlan != nil)
            Button("下一张") { browser?.move(1) }.keyboardShortcut(.rightArrow, modifiers: []).disabled(browser?.canNext != true || browser?.deletePlan != nil)
            Divider()
            Button("放大") { browser?.requestZoom(.zoomIn) }.keyboardShortcut("=").disabled(browser?.photo == nil || browser?.deletePlan != nil || browser?.galleryExpanded == true)
            Button("缩小") { browser?.requestZoom(.zoomOut) }.keyboardShortcut("-").disabled(browser?.photo == nil || browser?.deletePlan != nil || browser?.galleryExpanded == true)
            Button("适应窗口") { browser?.requestZoom(.fit) }.keyboardShortcut("0").disabled(browser?.photo == nil || browser?.deletePlan != nil || browser?.galleryExpanded == true)
            Button("实际大小（100%）") { browser?.requestZoom(.actual) }.keyboardShortcut("1").disabled(browser?.photo == nil || browser?.deletePlan != nil || browser?.galleryExpanded == true)
            Divider()
            Button(browser?.includeRaw == true ? "隐藏 RAW 照片" : "显示 RAW 照片") {
                if let browser { browser.setIncludeRaw(!browser.includeRaw) }
            }.keyboardShortcut("r", modifiers: [.command, .shift]).disabled(browser?.folder == nil || browser?.deletePlan != nil)
            Divider()
            Button("移到废纸篓…") { browser?.askDelete() }.keyboardShortcut(.delete).disabled(browser?.selectedAsset == nil || browser?.deletePlan != nil)
        }
        CommandGroup(after: .sidebar) {
            Button(showFilmstrip ? "隐藏缩略图栏" : "显示缩略图栏") { showFilmstrip.toggle() }
                .keyboardShortcut("t", modifiers: [.command, .option])
        }
        CommandGroup(replacing: .help) {
            Button("RAW 相机兼容…") { openWindow(id: "compatibility") }
            Button("使用说明") {
                if let url = AppResources.bundle.url(forResource: "Help", withExtension: "html", subdirectory: "Resources") { NSWorkspace.shared.open(url) }
            }
        }
    }
}
