import AppKit
import CoreGraphics

/// A chosen capture region: which display, and the rectangle in that display's
/// coordinate space (points, top-left origin) — exactly what
/// `SCStreamConfiguration.sourceRect` expects.
struct RegionSelection {
    let displayID: CGDirectDisplayID
    let rect: CGRect
}

/// Presents a dimmed, crosshair overlay on every screen and lets the user drag a
/// rectangle to pick a capture region (like the native screenshot tool). Esc — or
/// a click without a drag — cancels. The completion fires exactly once.
final class RegionSelector {
    private var windows: [OverlayWindow] = []
    private var completion: ((RegionSelection?) -> Void)?

    /// Show the overlays. `completion(nil)` means the user cancelled.
    func begin(_ completion: @escaping (RegionSelection?) -> Void) {
        guard windows.isEmpty else { return }
        self.completion = completion

        for screen in NSScreen.screens {
            let window = OverlayWindow(screen: screen)
            let view = SelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.onFinish = { [weak self] rectInScreen in self?.finish(rectInScreen, on: screen) }
            view.onCancel = { [weak self] in self?.finish(nil, on: screen) }
            window.contentView = view
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(view)
            windows.append(window)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func finish(_ rectInScreen: NSRect?, on screen: NSScreen) {
        let report = completion
        completion = nil
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()

        guard let rectInScreen, rectInScreen.width >= 4, rectInScreen.height >= 4,
              let displayID = screen.displayID
        else { report?(nil); return }

        // Convert the global (bottom-left origin) rect to the display's local
        // top-left-origin point space used by SCStreamConfiguration.sourceRect.
        let frame = screen.frame
        let local = CGRect(
            x: rectInScreen.minX - frame.minX,
            y: frame.maxY - rectInScreen.maxY,
            width: rectInScreen.width,
            height: rectInScreen.height
        )
        report?(RegionSelection(displayID: displayID, rect: local))
    }
}

/// Borderless, transparent, click-through-disabled window that floats above
/// everything and can become key (so it receives the Esc keypress).
final class OverlayWindow: NSWindow {
    init(screen: NSScreen) {
        // Designated initializer (the screen: variant is a convenience init).
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        setFrame(screen.frame, display: true)
    }

    override var canBecomeKey: Bool { true }
}

/// Draws the dim overlay + rubber-band selection and reports the dragged rect in
/// global screen coordinates.
final class SelectionView: NSView {
    var onFinish: ((NSRect) -> Void)?   // global screen rect
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var selection: NSRect = .zero

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.28).setFill()
        bounds.fill()
        guard selection.width > 0, selection.height > 0 else { return }
        selection.fill(using: .clear) // punch a transparent hole over the selection
        NSColor.white.setStroke()
        let outline = NSBezierPath(rect: selection)
        outline.lineWidth = 1.5
        outline.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        selection = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        selection = NSRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer { startPoint = nil }
        guard selection.width >= 4, selection.height >= 4, let window else {
            onCancel?()
            return
        }
        onFinish?(window.convertToScreen(selection))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onCancel?() } // Esc
        else { super.keyDown(with: event) }
    }
}
