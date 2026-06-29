import AppKit
import CoreGraphics

extension NSScreen {
    /// The CoreGraphics display ID backing this screen (used to line NSScreen up
    /// with ScreenCaptureKit's SCDisplay).
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    /// Backing scale (1 on non-Retina, 2 on Retina) for a given display ID.
    /// ScreenCaptureKit reports display size in points; the capture dimensions
    /// must be in pixels, so we multiply by this. Defaults to 2 if the display
    /// isn't found (the common Retina case).
    static func backingScale(for displayID: CGDirectDisplayID) -> CGFloat {
        for screen in screens where screen.displayID == displayID {
            return screen.backingScaleFactor
        }
        return 2
    }
}
