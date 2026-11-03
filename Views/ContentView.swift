import SwiftUI
import PhotoStudioCore

struct ContentView: View {
    @State private var browser = BrowserStore()
    @State private var started = false
    @State private var dropTargeted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("showFilmstrip") private var showFilmstrip = true
    var body: some View {
        NavigationSplitView {
            SidebarView(browser: browser)
        } detail: {
            GlassEffectContainer(spacing: 8) {
                VStack(spacing: 10) {
                    if browser.folder != nil {
                        ViewerHeaderView(browser: browser)
                    }
                    viewerArea
                }
                .padding(12)
            }
        }
        .navigationTitle(browser.directoryName ?? "PhotoStudio")
        .toolbar { toolbar }
        .toolbarBackgroundVisibility(.automatic, for: .windowToolbar)
        .frame(minWidth: 990, minHeight: 650)
        .focusedSceneValue(\.photoBrowser, browser)
        .disabled(browser.deletePlan != nil)
        .accessibilityHidden(browser.deletePlan != nil)
        .overlay {
            ZStack {
                if let plan = browser.deletePlan {
                    Color.black.opacity(0.12).ignoresSafeArea()
                        .contentShape(Rectangle()).onTapGesture { }
                        .accessibilityHidden(true)
                    GlassEffectContainer {
                        DeleteConfirmationView(plan: plan, browser: browser)
                    }
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97)))
                }
            }
            .animation(.easeOut(duration: reduceMotion ? 0.12 : 0.18), value: browser.deletePlan?.id)
        }
        .alert(item: $browser.alert) { value in Alert(title: Text(value.title), message: Text(value.message), dismissButton: .default(Text("好"))) }
        .dropDestination(for: URL.self) { urls, _ in browser.openURLs(urls); return !urls.isEmpty } isTargeted: { dropTargeted = $0 }
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 12).strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [9, 5]))
                    .padding(10).background(Color.accentColor.opacity(0.06)).allowsHitTesting(false)
            }
        }
        .task {
            guard !started else { return }; started = true
            let pending = OpenRequests.shared.consume()
            if pending.isEmpty { browser.start() } else { browser.openURLs(pending) }
        }
        .onChange(of: OpenRequests.shared.revision) { _, _ in
            let pending = OpenRequests.shared.consume()
            if !pending.isEmpty { browser.openURLs(pending) }
        }
        .onChange(of: browser.visible.isEmpty) { _, empty in if empty { browser.galleryExpanded = false } }
        .onChange(of: browser.deletePlan?.id) { _, plan in if plan == nil { browser.canvasFocusRequest = UUID() } }
    }
    private var viewerArea: some View {
        GeometryReader { geometry in
            let expanded = browser.galleryExpanded && !browser.visible.isEmpty
            let hasFooter = browser.folder != nil
            let compactHeight: CGFloat = hasFooter ? (showFilmstrip && !browser.visible.isEmpty ? 148 : 32) : 0
            ZStack(alignment: .bottom) {
                // The preview's layout is independent of the drawer, including at 100% zoom.
                VStack(spacing: hasFooter ? 10 : 0) {
                    preview
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .backgroundExtensionEffect(isEnabled: browser.photo != nil)
                        .overlay {
                            if !expanded { previewNavigation }
                        }
                        .clipped()
                        .disabled(expanded)
                        .allowsHitTesting(!expanded)
                        .accessibilityHidden(expanded)
                    if hasFooter {
                        Color.clear.frame(height: compactHeight).accessibilityHidden(true)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                if hasFooter {
                    ThumbnailDrawerView(browser: browser, showFilmstrip: showFilmstrip,
                                        compactHeight: compactHeight, onToggle: toggleGallery,
                                        onClose: { setGalleryExpanded(false) })
                }
            }
        }
    }
    private func toggleGallery() {
        setGalleryExpanded(!browser.galleryExpanded)
    }
    private func setGalleryExpanded(_ expanded: Bool) {
        guard browser.galleryExpanded != expanded else { return }
        browser.galleryExpanded = expanded
        if !expanded { browser.canvasFocusRequest = UUID() }
    }
    @ViewBuilder private var previewNavigation: some View {
        if browser.selectedAsset != nil {
            HStack {
                Button { browser.move(-1) } label: {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)).frame(width: 32, height: 34)
                }
                .disabled(!browser.canPrevious).help("上一张（←）")
                .accessibilityLabel("预览上一张").accessibilityIdentifier("previewPrevious")
                Spacer()
                Button { browser.move(1) } label: {
                    Image(systemName: "chevron.right").font(.system(size: 17, weight: .semibold)).frame(width: 32, height: 34)
                }
                .disabled(!browser.canNext).help("下一张（→）")
                .accessibilityLabel("预览下一张").accessibilityIdentifier("previewNext")
            }
            .buttonStyle(.glass).buttonBorderShape(.circle)
            .padding(.horizontal, 18)
        }
    }
    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button(action: browser.addFolders) { Label("添加文件夹", systemImage: "folder.badge.plus") }.help("添加文件夹（⇧⌘O）")
            Button(action: browser.openImage) { Label("打开照片", systemImage: "photo.badge.plus") }.help("打开照片（⌘O）")
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Button { browser.move(-1) } label: { Label("上一张", systemImage: "chevron.left") }.disabled(!browser.canPrevious).help("上一张（←）")
            Text(browser.selectedIndex.map { "\($0 + 1) / \(browser.visible.count)" } ?? "— / —")
                .font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary).frame(minWidth: 58)
            Button { browser.move(1) } label: { Label("下一张", systemImage: "chevron.right") }.disabled(!browser.canNext).help("下一张（→）")
        }
        ToolbarSpacer(.fixed, placement: .primaryAction)
        ToolbarItemGroup(placement: .primaryAction) {
            Button { browser.requestZoom(.zoomOut) } label: { Label("缩小", systemImage: "minus.magnifyingglass") }.help("缩小（−）").disabled(browser.photo == nil || browser.galleryExpanded)
            Text(browser.photo == nil ? "—" : "\(Int(browser.zoomPercent.rounded()))%")
                .font(.system(size: 11, design: .monospaced)).frame(width: 46).foregroundStyle(.secondary)
            Button { browser.requestZoom(.zoomIn) } label: { Label("放大", systemImage: "plus.magnifyingglass") }.help("放大（+）").disabled(browser.photo == nil || browser.galleryExpanded)
        }
        ToolbarSpacer(.fixed, placement: .primaryAction)
        ToolbarItemGroup(placement: .primaryAction) {
            Button { browser.requestZoom(.fit) } label: { Label("适应窗口", systemImage: "arrow.down.right.and.arrow.up.left") }
                .help("适应窗口（⌘0）").disabled(browser.photo == nil || browser.galleryExpanded)
            Button("100%") { browser.requestZoom(.actual) }.font(.system(size: 11, design: .monospaced)).help("实际像素大小（⌘1）").disabled(browser.photo == nil || browser.galleryExpanded)
        }
        ToolbarSpacer(.fixed, placement: .primaryAction)
        ToolbarItem(placement: .primaryAction) {
            Button(action: browser.askDelete) { Label("移到废纸篓", systemImage: "trash") }
                .disabled(browser.selectedAsset == nil || browser.isDeleting).help("移到废纸篓（⌘⌫）")
                .accessibilityIdentifier("trashPhoto")
        }
    }
    @ViewBuilder private var preview: some View {
        if let photo = browser.photo, let asset = browser.selectedAsset {
            PhotoCanvas(image: photo.image, imageID: asset.cacheKey, request: browser.zoomRequest, focusRequest: browser.canvasFocusRequest,
                        onZoom: { percent, fit in browser.zoomPercent = percent; browser.isFit = fit },
                        onNavigate: browser.move, onDelete: browser.askDelete)
                .padding(0)
        } else if browser.isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.regular)
                Text(browser.selectedAsset?.isRaw == true ? "正在解码 RAW 原图…" : "正在打开照片…").font(.system(size: 12)).foregroundStyle(.secondary)
                Text(browser.selectedAsset?.name ?? "").font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary)
            }
        } else if let error = browser.loadError {
            VStack(spacing: 15) {
                Image(systemName: "photo.badge.exclamationmark").font(.system(size: 36, weight: .light)).foregroundStyle(.secondary)
                Text("暂时无法显示这张照片").font(.title3.weight(.semibold))
                Text(error).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 490).textSelection(.enabled)
                HStack {
                    Button("重新尝试") { browser.select(browser.selection, force: true) }
                    if browser.canNext { Button("查看下一张") { browser.move(1) }.buttonStyle(.glassProminent) }
                }.padding(.top, 6)
            }.padding(30)
        } else if browser.isScanning {
            ProgressView("正在读取文件夹…").font(.callout)
        } else if let error = browser.scanError {
            VStack(spacing: 15) {
                Image(systemName: "externaldrive.badge.exclamationmark").font(.system(size: 35, weight: .light)).foregroundStyle(.secondary)
                Text("文件夹暂时不可用").font(.title3.weight(.semibold))
                Text(error).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 440)
                HStack { Button("重试") { browser.refresh() }; Button("重新选择文件夹…", action: browser.relocateFolder).buttonStyle(.glassProminent) }
            }.padding(30)
        } else if browser.folder != nil {
            VStack(spacing: 14) {
                Image(systemName: "photo.on.rectangle.angled").font(.system(size: 38, weight: .ultraLight)).foregroundStyle(.tertiary)
                Text(browser.rawCount > 0 ? "这个文件夹中有 \(browser.rawCount) 张 RAW 照片" : "这里还没有可浏览的照片").font(.title3.weight(.medium))
                Text(browser.rawCount > 0 ? "开启“包含 RAW”，即可解码浏览原图。" : "在侧栏展开文件夹，选择子文件夹查看其中的照片。")
                    .font(.callout).foregroundStyle(.secondary)
                if browser.rawCount > 0 {
                    Button("显示 RAW 照片") { browser.setIncludeRaw(true) }.buttonStyle(.glassProminent)
                } else { Button("刷新文件夹") { browser.refresh() } }
            }
        } else { WelcomeView(browser: browser) }
    }
}
