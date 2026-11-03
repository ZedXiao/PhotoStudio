import SwiftUI

struct ThumbnailDrawerView: View {
    let browser: BrowserStore
    let showFilmstrip: Bool
    let compactHeight: CGFloat
    let onToggle: () -> Void
    let onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var expanded: Bool { browser.galleryExpanded && !browser.visible.isEmpty }

    var body: some View {
        GeometryReader { geometry in
            let canExpand = !browser.visible.isEmpty
            let handleRise: CGFloat = canExpand ? 10 : 0
            let fullHeight = geometry.size.height
            let shadowBleed: CGFloat = 24
            let hiddenOffset = fullHeight + shadowBleed * 2 + 4
            let shape = ThumbnailDrawerShape(handleRise: handleRise)
            let slide: Animation? = reduceMotion ? nil : .easeOut(duration: 0.22)

            ZStack(alignment: .bottom) {
                // The compact strip never changes size or trades places with the large grid.
                GlassEffectContainer {
                    ZStack(alignment: .top) {
                        ViewerFooterView(browser: browser, showFilmstrip: showFilmstrip)
                            .frame(width: geometry.size.width, height: compactHeight, alignment: .top)
                            .padding(.top, handleRise)
                        if canExpand { handle(isExpanded: false) }
                    }
                    .frame(width: geometry.size.width, height: compactHeight + handleRise)
                    .clipShape(shape)
                    .contentShape(shape)
                    .glassEffect(.regular, in: shape)
                }
                .frame(width: geometry.size.width, height: fullHeight, alignment: .bottom)
                // Clip at the moving seam, leaving space around the outer glass shadow.
                .clipShape(DrawerUnderlayClip(revealedHeight: expanded ? 0 : hiddenOffset,
                                             shadowBleed: shadowBleed))
                .animation(slide, value: expanded)
                .disabled(expanded)
                .allowsHitTesting(!expanded)
                .accessibilityHidden(expanded)

                // A separate, fixed-size layer moves off screen. There is no crossfade to
                // small thumbnails, animated height, or glass-shape morph before it moves.
                GlassEffectContainer {
                    ZStack(alignment: .top) {
                        PhotoGalleryView(browser: browser, onClose: onClose)
                            .frame(width: geometry.size.width, height: max(0, fullHeight - handleRise))
                            .padding(.top, handleRise)
                        if canExpand { handle(isExpanded: true) }
                    }
                    .frame(width: geometry.size.width, height: fullHeight)
                    .clipShape(shape)
                    .contentShape(shape)
                    .glassEffect(.regular, in: shape)
                }
                .frame(width: geometry.size.width, height: fullHeight)
                .offset(y: expanded ? 0 : hiddenOffset)
                .animation(slide, value: expanded)
                .clipShape(DrawerUnderlayClip(revealedHeight: hiddenOffset,
                                             shadowBleed: shadowBleed))
                .disabled(!expanded)
                .allowsHitTesting(expanded)
                .accessibilityHidden(!expanded)
            }
            .frame(width: geometry.size.width, height: fullHeight, alignment: .bottom)
        }
    }

    private func handle(isExpanded: Bool) -> some View {
        Button(action: isExpanded ? onClose : onToggle) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                .resizable().scaledToFit().frame(width: 11, height: 7)
                .foregroundStyle(.primary)
                .frame(width: 72, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(isExpanded ? .cancelAction : nil)
        .help(isExpanded ? "收起缩略图（Esc）" : "展开缩略图，双击照片返回预览")
        .accessibilityLabel(isExpanded ? "收起缩略图" : "展开缩略图")
        .accessibilityIdentifier("togglePhotoGallery")
    }
}

/// A moving clip reveals the stationary filmstrip as the large drawer passes it.
private struct DrawerUnderlayClip: Shape {
    var revealedHeight: CGFloat
    let shadowBleed: CGFloat
    var animatableData: CGFloat {
        get { revealedHeight }
        set { revealedHeight = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX - shadowBleed, y: rect.minY - shadowBleed,
                    width: rect.width + shadowBleed * 2,
                    height: min(rect.height + shadowBleed, max(0, revealedHeight)) + shadowBleed))
    }
}

/// A shallow raised handle is part of the same glass silhouette as the drawer.
private struct ThumbnailDrawerShape: Shape {
    let handleRise: CGFloat
    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }
        guard handleRise > 0 else { return RoundedRectangle(cornerRadius: 20).path(in: rect) }
        let top = min(handleRise, rect.height)
        let radius = min(20, (rect.height - top) / 2, rect.width / 2)
        let center = rect.midX
        let halfWidth = min(52, max(0, rect.width / 2 - radius))
        let crownHalfWidth = min(18, halfWidth / 2)
        var path = Path()
        path.move(to: CGPoint(x: radius, y: top))
        path.addLine(to: CGPoint(x: center - halfWidth, y: top))
        // A broad, level crown keeps the tab from reading as a pointed peak.
        addShoulder(to: &path, from: CGPoint(x: center - halfWidth, y: top),
                    to: CGPoint(x: center - crownHalfWidth, y: 0))
        path.addLine(to: CGPoint(x: center + crownHalfWidth, y: 0))
        addShoulder(to: &path, from: CGPoint(x: center + crownHalfWidth, y: 0),
                    to: CGPoint(x: center + halfWidth, y: top))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: top))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: top + radius), control: CGPoint(x: rect.maxX, y: top))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.maxY - radius), control: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: top + radius))
        path.addQuadCurve(to: CGPoint(x: radius, y: top), control: CGPoint(x: 0, y: top))
        path.closeSubpath()
        return path
    }

    /// A clamped cubic spline meets each horizontal edge with zero slope and curvature.
    private func addShoulder(to path: inout Path, from start: CGPoint, to end: CGPoint) {
        let width = end.x - start.x
        let rise = end.y - start.y
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: start.x + width * x, y: start.y + rise * y)
        }
        path.addCurve(to: point(1 / 3, 1 / 6),
                      control1: point(1 / 9, 0), control2: point(2 / 9, 0))
        path.addCurve(to: point(2 / 3, 5 / 6),
                      control1: point(4 / 9, 1 / 3), control2: point(5 / 9, 2 / 3))
        path.addCurve(to: end,
                      control1: point(7 / 9, 1), control2: point(8 / 9, 1))
    }
}
