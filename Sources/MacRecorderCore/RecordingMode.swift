/// The two ways MacRecorder can record, identified by their binding token.
/// Each mode has a user-reassignable global shortcut and a menu item.
public enum RecordingMode: String, CaseIterable, Sendable {
    /// Record the entire main display.
    case fullScreen = "record.fullScreen"
    /// Drag a rectangle and record just that region.
    case region = "record.region"

    /// The HotkeyKit binding token for this mode.
    public var token: String { rawValue }

    /// Human-readable label for the menu and preferences UI.
    public var label: String {
        switch self {
        case .fullScreen: return "Record Entire Screen"
        case .region: return "Record Selected Area"
        }
    }

    public init?(token: String) { self.init(rawValue: token) }
}
