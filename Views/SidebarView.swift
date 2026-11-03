import SwiftUI

struct SidebarView: View {
    let browser: BrowserStore

    // Stable, individually identified List rows avoid OutlineView reusing a disclosure label
    // for an asynchronous loading child when its content switches to a folder or a leaf.
    private var rows: [FolderSidebarRow] {
        var result: [FolderSidebarRow] = []
        func append(_ url: URL, root: FolderEntry, depth: Int) {
            result.append(FolderSidebarRow(root: root, url: url, depth: depth))
            if browser.library.settings(for: url).expanded {
                for child in browser.tree.children[url] ?? [] { append(child, root: root, depth: depth + 1) }
            }
        }
        for root in browser.library.folders { append(root.url, root: root, depth: 0) }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: Binding(get: { browser.location }, set: { browser.chooseDirectory($0) })) {
                Section("文件夹") {
                    ForEach(rows) { row in
                        FolderSidebarCell(browser: browser, row: row)
                            .tag(row.id)
                            .listRowInsets(EdgeInsets(top: 2, leading: 8 + CGFloat(row.depth) * 16, bottom: 2, trailing: 6))
                    }
                }
            }
            .listStyle(.sidebar)
            .environment(\.defaultMinListRowHeight, 34)
            .disabled(browser.isDeleting || browser.deletePlan != nil)
            .overlay {
                if browser.library.folders.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus").font(.system(size: 25, weight: .light))
                        Text("添加拍摄文件夹").font(.callout)
                        Text("照片会保留在原位置").font(.caption)
                    }
                    .foregroundStyle(.secondary).padding(.bottom, 60)
                    .allowsHitTesting(false)
                }
            }
            Button(action: browser.addFolders) {
                Label("添加文件夹", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.glass).controlSize(.large)
            .padding(12)
            .accessibilityIdentifier("addFolderSidebar")
        }
        .navigationSplitViewColumnWidth(min: 210, ideal: 250, max: 380)
    }
}

private struct FolderSidebarRow: Identifiable {
    let root: FolderEntry
    let url: URL
    let depth: Int
    var id: FolderLocation { FolderLocation(rootID: root.id, url: url) }
    var isRoot: Bool { depth == 0 }
}

private struct FolderSidebarCell: View {
    let browser: BrowserStore
    let row: FolderSidebarRow
    private var expanded: Bool { browser.library.settings(for: row.url).expanded }
    private var expandable: Bool { browser.tree.children[row.url]?.isEmpty != true }

    var body: some View {
        HStack(spacing: 8) {
            if expandable {
                Button {
                    let value = !expanded
                    browser.library.setExpanded(value, for: row.url)
                    if value { browser.tree.load(row.url) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .foregroundStyle(.secondary)
                        .frame(width: 14, height: 28).contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("\(expanded ? "收起" : "展开") \(row.url.lastPathComponent)")
                .accessibilityIdentifier("disclosure-\(row.url.path)")
            } else {
                Color.clear.frame(width: 14, height: 28).accessibilityHidden(true)
            }
            Image(systemName: expanded && expandable ? "folder.fill" : "folder")
                .font(.system(size: row.isRoot ? 19 : 16)).foregroundStyle(.secondary)
                .frame(width: 22).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.url.lastPathComponent).fontWeight(row.isRoot ? .medium : .regular).lineLimit(1)
                if row.isRoot {
                    Text(row.url.deletingLastPathComponent().path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if browser.tree.loading.contains(row.url) {
                ProgressView().controlSize(.mini).frame(width: 16, height: 16)
                    .accessibilityLabel("正在读取 \(row.url.lastPathComponent)")
            } else if let error = browser.tree.errors[row.url] {
                Button { browser.tree.load(row.url, force: true) } label: {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(.secondary).frame(width: 16, height: 20)
                }
                .buttonStyle(.borderless).help("读取失败，点此重试\n\(error)")
                .accessibilityLabel("重新读取 \(row.url.lastPathComponent)")
            }
            if row.isRoot {
                Button { browser.removeFolder(row.root.id) } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 13)).foregroundStyle(.tertiary)
                        .frame(width: 24, height: 28).contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("从列表中移除，不删除磁盘中的照片")
                .accessibilityLabel("移除文件夹 \(row.root.name)")
                .accessibilityIdentifier("removeFolder-\(row.root.id)")
            }
        }
        .frame(height: row.isRoot ? 44 : 30)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .contextMenu {
            Button("在访达中显示") { NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: row.url.path) }
            Button("刷新") { browser.chooseDirectory(row.id); browser.refresh(); browser.tree.load(row.url, force: true) }
            if row.isRoot {
                Divider()
                Button("从列表中移除") { browser.removeFolder(row.root.id) }
            }
        }
        .help(row.url.path)
        .onAppear { if expanded { browser.tree.load(row.url) } }
    }
}
