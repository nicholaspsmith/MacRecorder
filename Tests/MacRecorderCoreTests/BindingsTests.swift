import HotkeyKit
import XCTest
@testable import MacRecorderCore

final class BindingsTests: XCTestCase {
    func testDefaultsCoverBothModes() {
        let tokens = BindingStore.defaults.map(\.token)
        XCTAssertEqual(tokens, [RecordingMode.fullScreen.token, RecordingMode.region.token])
    }

    func testDefaultTriggers() {
        let byToken = Dictionary(uniqueKeysWithValues: BindingStore.defaults.map { ($0.token, $0.trigger) })
        XCTAssertEqual(byToken[RecordingMode.fullScreen.token], .key(23, [.command, .shift]))      // ⌘⇧5
        XCTAssertEqual(byToken[RecordingMode.region.token], .key(22, [.command, .shift]))          // ⌘⇧6
    }

    func testDefaultsDoNotRepeatOnHold() {
        XCTAssertTrue(BindingStore.defaults.allSatisfy { !$0.repeatsOnHold })
    }

    func testResolveWithNoOverridesReturnsDefaults() {
        XCTAssertEqual(BindingStore.resolve(overrides: [:]), BindingStore.defaults)
    }

    func testResolveAppliesOverrideToOneModeOnly() {
        let newTrigger: Trigger = .key(15, [.control, .option]) // ⌃⌥R
        let resolved = BindingStore.resolve(overrides: [RecordingMode.fullScreen.token: newTrigger])

        let byToken = Dictionary(uniqueKeysWithValues: resolved.map { ($0.token, $0.trigger) })
        XCTAssertEqual(byToken[RecordingMode.fullScreen.token], newTrigger)
        // The region binding is untouched.
        XCTAssertEqual(byToken[RecordingMode.region.token], .key(22, [.command, .shift]))
    }

    func testResolveIgnoresUnknownTokens() {
        let resolved = BindingStore.resolve(overrides: ["bogus.token": .key(0, [])])
        XCTAssertEqual(resolved, BindingStore.defaults)
    }

    func testStopEscBindingIsBareEscapeAndNotADefault() {
        XCTAssertEqual(BindingStore.stopEsc.trigger, .key(53, []))
        XCTAssertEqual(BindingStore.stopEsc.token, BindingStore.stopToken)
        XCTAssertFalse(BindingStore.defaults.contains { $0.token == BindingStore.stopToken })
    }
}
