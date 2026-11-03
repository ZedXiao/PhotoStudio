import SwiftUI
import PhotoStudioCore

struct FilmstripView: View {
    let browser: BrowserStore
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10) {
                    ForEach(browser.visible) { asset in
                        ThumbnailCell(asset: asset, selected: browser.selection == asset.id) { browser.select(asset.id) }
                            .id(asset.id)
                    }
                }
                .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .horizontal)
            .onChange(of: browser.selection) { _, value in if let value { proxy.scrollTo(value, anchor: .center) } }
            .onAppear { if let selection = browser.selection { proxy.scrollTo(selection, anchor: .center) } }
        }
        .frame(height: 116)
        .disabled(browser.isDeleting)
    }
}

struct ThumbnailCell: View {
    let asset: PhotoAsset
    let selected: Bool
    var width: CGFloat = 100
    var onOpen: (() -> Void)? = nil
    let action: () -> Void
    @State private var thumbnail: CGImage?
    @State private var finished = false
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7).fill(Color(nsColor: .underPageBackgroundColor))
                    if let thumbnail {
                        Image(decorative: thumbnail, scale: 1)
                            .resizable().scaledToFit().padding(3)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        Image(systemName: finished ? "photo" : "ellipsis")
                            .foregroundStyle(.tertiary).frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: width - 6, height: (width - 6) * 0.745)
                .overlay(alignment: .bottomTrailing) {
                    Text(asset.isRaw ? "RAW" : asset.format)
                        .font(.system(size: width > 120 ? 10 : 8, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .foregroundStyle(.white).background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 3))
                        .padding(5)
                }
                .padding(3)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Color.accentColor : .clear, lineWidth: 2))
                Text(asset.name).font(.system(size: width > 120 ? 12 : 10)).foregroundStyle(selected ? .primary : .secondary)
                    .lineLimit(1).truncationMode(.middle).frame(width: width)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture(count: 2).onEnded { onOpen?() })
        .help(onOpen == nil ? asset.name : "\(asset.name)\n双击打开照片，返回预览")
        .accessibilityLabel("\(asset.name)，\(asset.isRaw ? "RAW" : asset.format)")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityAction(named: "打开预览") { onOpen?() ?? action() }
        .task(id: asset.cacheKey) {
            thumbnail = nil; finished = false
            let result = await ImagePipeline.shared.thumbnail(asset)
            guard !Task.isCancelled else { return }
            thumbnail = result; finished = true
        }
    }
}
