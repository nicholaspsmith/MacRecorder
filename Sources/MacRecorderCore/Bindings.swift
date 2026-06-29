import HotkeyKit

/// Built-in default shortcuts for the two recording modes plus merge logic for
/// user overrides. Pure + testable (mirrors KeyLightCore's BindingStore).
///
/// Key codes: ANSI "5" == 23, "6" == 22, Esc == 53. `repeatsOnHold` is false so
/// holding a shortcut doesn't re-trigger start/stop.
public enum BindingStore {
    /// The user-reassignable bindings, in display order. ⌘⇧5 records the whole
    /// display; ⌘⇧6 records a drag-selected region. Both override the native
    /// Screenshot shortcuts (the tap swallows them so Screenshot never appears).
    public static let defaults: [Binding] = [
        Binding(
            token: RecordingMode.fullScreen.token,
            trigger: .key(23, [.command, .shift]),
            repeatsOnHold: false
        ),
        Binding(
            token: RecordingMode.region.token,
            trigger: .key(22, [.command, .shift]),
            repeatsOnHold: false
        ),
    ]

    /// Merge user `overrides` (token → replacement trigger) over the defaults.
    /// Overrides for unknown tokens are ignored; order is preserved.
    public static func resolve(overrides: [String: Trigger]) -> [Binding] {
        defaults.map { binding in
            guard let trigger = overrides[binding.token] else { return binding }
            var updated = binding
            updated.trigger = trigger
            return updated
        }
    }

    /// Token for the fixed Esc-to-stop affordance.
    public static let stopToken = "record.stop"

    /// Fixed (non-rebindable) Esc-to-stop binding. Combined with the resolved
    /// mode bindings when the tap is registered — deliberately NOT in `defaults`,
    /// so it never shows up in the preferences list. Esc is only swallowed while
    /// a recording is active (the app passes it through otherwise).
    public static let stopEsc = Binding(
        token: stopToken,
        trigger: .key(53, []),
        repeatsOnHold: false
    )
}
