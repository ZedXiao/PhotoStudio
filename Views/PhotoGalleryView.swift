import SwiftUI

struct PhotoGalleryView: View {
    let browser: BrowserStore
    let onClose: () -> Void
    @FocusState private var galleryFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("照片总览", systemImage: "square.grid.2x2").font(.headline)
                Text("\(browser.visible.count) 张").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("单击选择 · 双击打开").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20).frame(height: 54)
            Divider().padding(.horizontal, 20)
            GeometryReader { geometry in
                let count = max(1, Int((geometry.size.width - 20) / 210))
                let cellWidth = max(100, (geometry.size.width - 40 - CGFloat(count - 1) * 16) / CGFloat(count))
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: 16), count: count), spacing: 20) {
                            ForEach(browser.visible) { asset in
                                ThumbnailCell(asset: asset, selected: browser.selection == asset.id, width: cellWidth, onOpen: {
                                    browser.select(asset.id)
                                    onClose()
                                }) { browser.select(asset.id) }
                                .id(asset.id)
                            }
                        }
                        .padding(20)
                    }
                    .scrollEdgeEffectStyle(.soft, for: .vertical)
                    .onChange(of: browser.galleryExpanded) { _, expanded in
                        if expanded, let selection = browser.selection { proxy.scrollTo(selection, anchor: .center) }
                    }
                }
            }
        }
        .accessibilityIdentifier("photoGallery")
        .focusable().focusEffectDisabled().focused($galleryFocused)
        .onChange(of: browser.galleryExpanded) { _, expanded in galleryFocused = expanded }
        .onKeyPress(.escape) { onClose(); return .handled }
    }
}
