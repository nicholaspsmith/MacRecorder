import XCTest
@testable import MacRecorderCore

final class OutputPathTests: XCTestCase {
    private let utc = TimeZone(identifier: "UTC")!

    func testFilenameFormatsNativeStyle() {
        // 1_000_000_000 == 2001-09-09 01:46:40 UTC.
        let date = Date(timeIntervalSince1970: 1_000_000_000)
        XCTAssertEqual(
            OutputPath.filename(for: date, timeZone: utc),
            "Screen Recording 2001-09-09 at 01.46.40.mov"
        )
    }

    func testFilenameUsesDotSeparatedTimeAndMovExtension() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01 00:00:00 UTC
        let name = OutputPath.filename(for: date, timeZone: utc)
        XCTAssertEqual(name, "Screen Recording 1970-01-01 at 00.00.00.mov")
        XCTAssertTrue(name.hasSuffix(".mov"))
        XCTAssertFalse(name.contains(":")) // ":" is illegal in HFS+ filenames
    }

    func testDownloadsURLEndsInDownloadsWithTheFilename() {
        let date = Date(timeIntervalSince1970: 0)
        let url = OutputPath.downloadsURL(for: date, timeZone: utc)
        XCTAssertEqual(url.lastPathComponent, OutputPath.filename(for: date, timeZone: utc))
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "Downloads")
    }
}
