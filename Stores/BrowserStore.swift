import AppKit
import Observation
import PhotoStudioCore

enum ZoomCommand: Equatable {
    case fit, actual, zoomIn, zoomOut
}
struct ZoomRequest: Equatable {
    let id = UUID()
    let command: ZoomCommand
}
struct BrowserAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor @Observable
final class BrowserStore {
    let library: LibraryStore
    let tree = FolderTreeStore()
    private(set) var folderID: UUID?
    private(set) var directory: URL?
    var galleryExpanded = false
    private(set) var snapshot = FolderSnapshot(assets: [])
    private(set) var visible: [PhotoAsset] = []
    private(set) var selection: URL?
    private(set) var photo: DecodedPhoto?
    private(set) var isScanning = false
    private(set) var isLoading = false
    private(set) var isDeleting = false
    private(set) var loadError: String?
    private(set) var scanError: String?
    var alert: BrowserAlert?
    var deletePlan: DeletePlan?
    var zoomRequest = ZoomRequest(command: .fit)
    var canvasFocusRequest = UUID()
    var zoomPercent: Double = 100
    var isFit = true
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var imageTask: Task<Void, Never>?
    @ObservationIgnored private var prefetchTask: Task<Void, Never>?
    @ObservationIgnored private var scanToken = DecodeCancellation()
    @ObservationIgnored private var decodeToken = DecodeCancellation()
    @ObservationIgnored private var prefetchToken = DecodeCancellation()
    @ObservationIgnored private var scanRevision = UUID()
    @ObservationIgnored private var decodeRevision = UUID()
    var folder: FolderEntry? { library.folder(folderID) }
    var location: FolderLocation? { folderID.flatMap { id in directory.map { FolderLocation(rootID: id, url: $0) } } }
    var directoryName: String? { directory?.lastPathComponent }
    var selectedAsset: PhotoAsset? { visible.first { $0.id == selection } }
    var selectedIndex: Int? { visible.firstIndex { $0.id == selection } }
    var rawCount: Int { snapshot.assets.filter(\.isRaw).count }
    var canPrevious: Bool { (selectedIndex ?? 0) > 0 && !isDeleting }
    var canNext: Bool { selectedIndex.map { $0 < visible.count - 1 } == true && !isDeleting }
    var includeRaw: Bool { directory.map { library.settings(for: $0).includeRaw } ?? false }

    init(library: LibraryStore? = nil) { self.library = library ?? .shared }
    func start() {
        if let id = library.lastFolderID, let root = library.folder(id) {
            let saved = library.lastDirectoryPath.map { URL(fileURLWithPath: $0, isDirectory: true).standardizedFileURL }
            let directory = saved.flatMap { $0.pathComponents.starts(with: root.url.standardizedFileURL.pathComponents) ? $0 : nil } ?? root.url
            chooseDirectory(FolderLocation(rootID: id, url: directory))
        }
        else if let first = library.folders.first { chooseFolder(first.id) }
    }
    func chooseFolder(_ id: UUID?) {
        chooseDirectory(library.folder(id).map { FolderLocation(rootID: $0.id, url: $0.url) })
    }
    func chooseDirectory(_ location: FolderLocation?) {
        guard !isDeleting, deletePlan == nil, self.location != location || scanError != nil else { return }
        folderID = location?.rootID; directory = location?.url
        library.lastFolderID = folderID; library.lastDirectoryPath = directory?.path
        snapshot = FolderSnapshot(assets: []); visible = []; select(nil)
        refresh()
    }
    func addFolders() {
        guard !isDeleting, deletePlan == nil else { return }
        let panel = NSOpenPanel()
        panel.title = "添加照片文件夹"; panel.prompt = "添加文件夹"
        panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = true
        if panel.runModal() == .OK { openURLs(panel.urls) }
    }
    func openImage() {
        guard !isDeleting, deletePlan == nil else { return }
        let panel = NSOpenPanel()
        panel.title = "打开照片"; panel.prompt = "打开"
        panel.canChooseDirectories = false; panel.canChooseFiles = true
        // File-type recognition happens in the scanner, including newer RAW extensions unknown to older macOS.
        if panel.runModal() == .OK { openURLs(panel.urls) }
    }
    func openURLs(_ urls: [URL]) {
        guard !isDeleting, deletePlan == nil else { return }
        var target: (FolderEntry, URL, URL?)?
        for url in urls where url.isFileURL {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                alert = BrowserAlert(title: "找不到文件", message: url.path); continue
            }
            if isDirectory.boolValue {
                let entry = library.add(url)
                if target == nil { target = (entry, entry.url, nil) }
            } else if PhotoFormats.isSupported(url) {
                let parent = url.deletingLastPathComponent().standardizedFileURL.resolvingSymlinksInPath()
                let entry = library.root(containing: parent) ?? library.add(parent)
                if PhotoFormats.isRaw(url) { library.setIncludeRaw(true, for: parent) }
                expandAncestors(of: parent, root: entry)
                if target == nil { target = (entry, parent, parent.appendingPathComponent(url.lastPathComponent)) }
            } else { alert = BrowserAlert(title: "暂不支持此文件", message: "请选择照片或相机 RAW 文件。\n\(url.lastPathComponent)") }
        }
        guard let target else { return }
        folderID = target.0.id; directory = target.1
        library.lastFolderID = folderID; library.lastDirectoryPath = directory?.path
        snapshot = FolderSnapshot(assets: []); visible = []; select(nil)
        refresh(preferred: target.2)
    }
    private func expandAncestors(of directory: URL, root: FolderEntry) {
        var ancestor = directory.deletingLastPathComponent()
        while ancestor.pathComponents.starts(with: root.url.standardizedFileURL.pathComponents) {
            library.setExpanded(true, for: ancestor); tree.load(ancestor)
            if ancestor.path == root.path { break }
            ancestor.deleteLastPathComponent()
        }
    }
    func refresh(preferred: URL? = nil) {
        guard !isDeleting, deletePlan == nil else { return }
        scanTask?.cancel(); scanToken.cancel(); scanToken = DecodeCancellation()
        let revision = UUID(); scanRevision = revision
        guard let directory else { isScanning = false; scanError = nil; return }
        isScanning = true; scanError = nil
        tree.load(directory, force: true)
        let token = scanToken
        let desired = preferred ?? selection
        scanTask = Task { [weak self] in
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try FolderScanner.scan(directory, cancelled: { token.isCancelled })
                }.value
                guard let self, !token.isCancelled, self.scanRevision == revision else { return }
                let previousKey = self.selectedAsset?.cacheKey
                self.snapshot = result
                self.tree.update(directory, children: result.subdirectories)
                self.visible = result.visible(includeRaw: self.includeRaw)
                self.isScanning = false
                let next = desired.flatMap { desired in self.visible.first { $0.id == desired }?.id } ?? self.visible.first?.id
                self.select(next, force: self.photo == nil || self.visible.first(where: { $0.id == next })?.cacheKey != previousKey)
            } catch is CancellationError {} catch {
                guard let self, self.scanRevision == revision else { return }
                self.isScanning = false
                self.scanError = "无法读取这个文件夹。它可能已移动、磁盘未连接，或没有访问权限。\n\(error.localizedDescription)"
                self.snapshot = FolderSnapshot(assets: []); self.visible = []; self.select(nil)
            }
        }
    }
    func setIncludeRaw(_ value: Bool) {
        guard let directory, !isDeleting, deletePlan == nil else { return }
        let oldVisible = visible
        let previous = selectedAsset
        library.setIncludeRaw(value, for: directory)
        visible = snapshot.visible(includeRaw: value)
        let removed = Set(oldVisible.filter { !visible.contains($0) }.map(\.id))
        let pairedJPEG = previous.flatMap { old in
            visible.first { !$0.isRaw && $0.stem == old.stem && $0.url.deletingLastPathComponent() == old.url.deletingLastPathComponent() }?.id
        }
        let next = visible.contains(where: { $0.id == selection }) ? selection :
            (pairedJPEG ?? PhotoSelection.afterRemoving(removed, from: oldVisible, selected: selection) ?? visible.first?.id)
        select(next)
    }
    func relocateFolder() {
        guard let folderID else { return }
        let panel = NSOpenPanel()
        panel.title = "重新选择照片文件夹"; panel.canChooseDirectories = true; panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            library.replace(folderID, with: url)
            directory = url.standardizedFileURL; library.lastDirectoryPath = directory?.path
            library.setExpanded(true, for: url); refresh()
        }
    }
    func removeFolder(_ id: UUID) {
        guard !isDeleting, deletePlan == nil else { return }
        library.remove(id)
        if folderID == id { chooseFolder(library.folders.first?.id) }
    }
    func select(_ url: URL?, force: Bool = false) {
        guard !isDeleting, url != selection || force else { return }
        imageTask?.cancel(); prefetchTask?.cancel(); decodeToken.cancel(); prefetchToken.cancel()
        decodeToken = DecodeCancellation(); prefetchToken = DecodeCancellation()
        let revision = UUID(); decodeRevision = revision
        selection = url; photo = nil; loadError = nil; isLoading = false
        requestZoom(.fit)
        guard let asset = selectedAsset else { return }
        isLoading = true
        let token = decodeToken
        imageTask = Task { [weak self] in
            do {
                let photo = try await ImagePipeline.shared.load(asset, cancellation: token)
                guard let self, !token.isCancelled, self.decodeRevision == revision else { return }
                self.photo = photo; self.isLoading = false
                CompatibilityStore.shared.record(asset, photo: photo)
                self.prefetch(after: asset, cost: photo.byteCost)
            } catch is CancellationError {} catch {
                guard let self, !token.isCancelled, self.decodeRevision == revision else { return }
                self.isLoading = false; self.loadError = error.localizedDescription
                CompatibilityStore.shared.recordFailure(asset)
            }
        }
    }
    private func prefetch(after asset: PhotoAsset, cost: Int) {
        guard cost < ImagePipeline.shared.cacheBudget / 2,
              let index = visible.firstIndex(of: asset), index + 1 < visible.count else { return }
        let next = visible[index + 1], token = prefetchToken
        prefetchTask = Task { _ = try? await ImagePipeline.shared.load(next, cancellation: token, prefetch: true) }
    }
    func move(_ offset: Int) {
        guard !isDeleting, deletePlan == nil, let index = selectedIndex else { return }
        let target = index + offset
        guard visible.indices.contains(target) else { return }
        select(visible[target].id)
    }
    func requestZoom(_ command: ZoomCommand) {
        guard deletePlan == nil else { return }
        zoomRequest = ZoomRequest(command: command)
    }
    func askDelete() {
        guard !isDeleting, deletePlan == nil, let asset = selectedAsset else { return }
        deletePlan = DeletePlan(primary: asset, allAssets: snapshot.assets)
    }
    func performDelete(_ plan: DeletePlan, includeRaw: Bool) {
        guard !isDeleting, deletePlan?.id == plan.id else { return }
        scanTask?.cancel(); scanToken.cancel(); scanRevision = UUID(); isScanning = false
        isDeleting = true
        Task {
            let result = await Task.detached(priority: .userInitiated) { TrashService.execute(plan, includeRaw: includeRaw) }.value
            let oldVisible = visible
            let next = PhotoSelection.afterRemoving(result.trashed, from: oldVisible, selected: selection)
            ImagePipeline.shared.invalidate(snapshot.assets.filter { result.trashed.contains($0.id) })
            snapshot = FolderSnapshot(assets: snapshot.assets.filter { !result.trashed.contains($0.id) }, warnings: snapshot.warnings, subdirectories: snapshot.subdirectories)
            visible = snapshot.visible(includeRaw: self.includeRaw)
            isDeleting = false; deletePlan = nil
            select(next, force: result.trashed.contains(selection ?? URL(fileURLWithPath: "/")))
            if !result.failures.isEmpty {
                try? await Task.sleep(for: .milliseconds(200))
                alert = BrowserAlert(title: "部分文件未能移到废纸篓", message: result.failures.map { "\($0.name)：\($0.reason)" }.joined(separator: "\n\n"))
            }
        }
    }
}
