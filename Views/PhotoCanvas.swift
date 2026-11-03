import AppKit
import SwiftUI
import PhotoStudioCore

struct PhotoCanvas: NSViewRepresentable {
    let image: CGImage
    let imageID: String
    let request: ZoomRequest
    let focusRequest: UUID
    @Environment(\.isEnabled) private var isEnabled
    let onZoom: (Double, Bool) -> Void
    let onNavigate: (Int) -> Void
    let onDelete: () -> Void

    func makeNSView(context: Context) -> PhotoScrollView {
        let view = PhotoScrollView()
        updateNSView(view, context: context)
        return view
    }
    func updateNSView(_ view: PhotoScrollView, context: Context) {
        view.onZoom = onZoom; view.onNavigate = onNavigate; view.onDelete = onDelete
        view.interactionsEnabled = isEnabled
        view.setImage(image, id: imageID)
        if isEnabled, view.lastFocusRequest != focusRequest {
            view.lastFocusRequest = focusRequest
            DispatchQueue.main.async { [weak view] in
                guard let view, view.interactionsEnabled else { return }
                view.window?.makeFirstResponder(view)
            }
        }
        if view.lastRequest != request.id {
            view.lastRequest = request.id
            DispatchQueue.main.async { [weak view] in view?.perform(request.command) }
        }
    }
}

private final class CenteredClipView: NSClipView {
    override func constrainBoundsRect(_ proposed: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposed)
        guard let document = documentView else { return rect }
        if rect.width > document.frame.width { rect.origin.x = (document.frame.width - rect.width) / 2 }
        if rect.height > document.frame.height { rect.origin.y = (document.frame.height - rect.height) / 2 }
        return rect
    }
}

final class PhotoScrollView: NSScrollView {
    private let imageView = CanvasImageView()
    private var imageID: String?
    private var pixelSize = CGSize.zero
    private var lastViewport = CGSize.zero
    private var magnificationObserver: NSKeyValueObservation?
    private(set) var fitMode = true
    private var lastReported: (Double, Bool)?
    private var swipeTracker = PhotoSwipeTracker()
    private var lastSwipeNavigationTime = -Double.infinity
    var lastRequest: UUID?
    var lastFocusRequest: UUID?
    var interactionsEnabled = true
    var onZoom: ((Double, Bool) -> Void)?
    var onNavigate: ((Int) -> Void)?
    var onDelete: (() -> Void)?
    override var acceptsFirstResponder: Bool { interactionsEnabled }

    init() {
        super.init(frame: .zero)
        let clip = CenteredClipView()
        clip.drawsBackground = false
        clip.focusRingType = .none
        contentView = clip
        drawsBackground = false
        borderType = .noBorder
        focusRingType = .none
        imageView.focusRingType = .none
        hasVerticalScroller = true; hasHorizontalScroller = true
        autohidesScrollers = true; scrollerStyle = .overlay
        allowsMagnification = true; minMagnification = 0.005; maxMagnification = 32
        imageView.canvas = self
        documentView = imageView
        magnificationObserver = observe(\.magnification, options: [.new]) { [weak self] _, _ in self?.report() }
        setAccessibilityIdentifier("photoCanvas")
        setAccessibilityLabel("照片预览；方向键或触控板左右滑动切图，加减键缩放，双击切换百分之百")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        resizeDocument()
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            if self.fitMode { self.fit() }
            if self.interactionsEnabled { window.makeFirstResponder(self) }
        }
    }
    func setImage(_ image: CGImage, id: String) {
        guard imageID != id else { return }
        imageID = id; pixelSize = CGSize(width: image.width, height: image.height)
        imageView.image = image
        resizeDocument(); fitMode = true
        DispatchQueue.main.async { [weak self] in
            self?.fit()
            if let self, self.interactionsEnabled { self.window?.makeFirstResponder(self) }
        }
    }
    private func resizeDocument() {
        let backingScale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        imageView.setFrameSize(CGSize(width: pixelSize.width / backingScale, height: pixelSize.height / backingScale))
    }
    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        resizeDocument()
        if fitMode { fit() }
        else { contentView.scroll(to: contentView.constrainBoundsRect(contentView.bounds).origin); reflectScrolledClipView(contentView) }
    }
    override func layout() {
        super.layout()
        let size = contentView.frame.size
        if size != lastViewport {
            lastViewport = size
            if fitMode { fit() }
        }
    }
    func perform(_ command: ZoomCommand) {
        guard interactionsEnabled else { return }
        switch command {
        case .fit: fit()
        case .actual: setZoom(1)
        case .zoomIn: setZoom(min(32, magnification * 1.25))
        case .zoomOut: setZoom(max(0.005, magnification / 1.25))
        }
    }
    func fit() {
        guard pixelSize.width > 0, contentView.frame.width > 0, contentView.frame.height > 0 else { return }
        fitMode = true
        let size = imageView.frame.size
        let factor = max(0.005, min(1, min(max(1, contentView.frame.width - 64) / size.width, max(1, contentView.frame.height - 64) / size.height)))
        if abs(magnification - factor) > 0.00001 { setMagnification(factor, centeredAt: NSPoint(x: size.width / 2, y: size.height / 2)) }
        // Recenter both axes explicitly after magnification, including narrow portrait images.
        var centered = contentView.bounds
        centered.origin = NSPoint(x: (size.width - centered.width) / 2, y: (size.height - centered.height) / 2)
        contentView.scroll(to: contentView.constrainBoundsRect(centered).origin)
        reflectScrolledClipView(contentView); report()
    }
    private func setZoom(_ value: CGFloat) {
        fitMode = false
        let center = NSPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
        setMagnification(value, centeredAt: center); report()
    }
    func toggleActual() { if fitMode { setZoom(1) } else { fit() } }
    override func magnify(with event: NSEvent) {
        guard interactionsEnabled else { return }
        fitMode = false
        swipeTracker.reset()
        super.magnify(with: event); report()
    }
    override func scrollWheel(with event: NSEvent) {
        guard interactionsEnabled else { return }
        guard fitMode, event.hasPreciseScrollingDeltas else { super.scrollWheel(with: event); return }
        let phase: PhotoSwipeTracker.Phase
        if event.phase.contains(.began) { phase = .began }
        else if event.phase.contains(.cancelled) { phase = .cancelled }
        else if event.phase.contains(.ended) { phase = .ended }
        else { phase = .changed }
        if let direction = swipeTracker.consume(dx: event.scrollingDeltaX, dy: event.scrollingDeltaY,
                                                phase: phase, momentum: !event.momentumPhase.isEmpty) {
            lastSwipeNavigationTime = event.timestamp
            onNavigate?(direction)
        }
        // Consume the rest of this gesture and its inertia instead of scrolling the fitted photo.
    }
    override func swipe(with event: NSEvent) {
        guard interactionsEnabled else { return }
        guard fitMode, abs(event.deltaX) > abs(event.deltaY), event.deltaX != 0 else { super.swipe(with: event); return }
        guard event.timestamp - lastSwipeNavigationTime > 0.25 else { return }
        lastSwipeNavigationTime = event.timestamp
        onNavigate?(event.deltaX < 0 ? 1 : -1)
    }
    private func report() {
        let value = Double(magnification * 100), fit = fitMode
        if let lastReported, abs(lastReported.0 - value) < 0.01 && lastReported.1 == fit { return }
        lastReported = (value, fit)
        DispatchQueue.main.async { [weak self] in self?.onZoom?(value, fit) }
    }
    override func mouseDown(with event: NSEvent) { if interactionsEnabled { window?.makeFirstResponder(self) } }
    override func keyDown(with event: NSEvent) {
        guard interactionsEnabled else { super.keyDown(with: event); return }
        if event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
            switch event.keyCode {
            case 123: onNavigate?(-1); return
            case 124: onNavigate?(1); return
            case 51, 117: onDelete?(); return
            default: break
            }
            switch event.charactersIgnoringModifiers {
            case "+", "=": perform(.zoomIn); return
            case "-", "_": perform(.zoomOut); return
            default: break
            }
        }
        super.keyDown(with: event)
    }
}

private final class CanvasImageView: NSView {
    weak var canvas: PhotoScrollView?
    var image: CGImage? { didSet { needsDisplay = true } }
    private var dragStart: NSPoint?
    private var scrollStart = NSPoint.zero
    override var acceptsFirstResponder: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        guard let image, let context = NSGraphicsContext.current?.cgContext else { return }
        context.interpolationQuality = .high
        context.draw(image, in: bounds)
    }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
    override func mouseDown(with event: NSEvent) {
        guard let canvas, canvas.interactionsEnabled else { return }
        window?.makeFirstResponder(canvas)
        if event.clickCount == 2 { canvas.toggleActual(); return }
        dragStart = event.locationInWindow; scrollStart = canvas.contentView.bounds.origin
        NSCursor.closedHand.push()
    }
    override func mouseDragged(with event: NSEvent) {
        guard let canvas, canvas.interactionsEnabled, let start = dragStart else { return }
        let current = event.locationInWindow
        let proposed = NSPoint(x: scrollStart.x - (current.x - start.x) / canvas.magnification,
                               y: scrollStart.y - (current.y - start.y) / canvas.magnification)
        var rect = canvas.contentView.bounds; rect.origin = proposed
        canvas.contentView.scroll(to: canvas.contentView.constrainBoundsRect(rect).origin)
        canvas.reflectScrolledClipView(canvas.contentView)
    }
    override func mouseUp(with event: NSEvent) {
        if dragStart != nil { NSCursor.pop() }; dragStart = nil
    }
}
