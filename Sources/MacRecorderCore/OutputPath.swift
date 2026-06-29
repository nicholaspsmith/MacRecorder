import Foundation

/// Builds the destination filename/URL for a finished recording. Pure +
/// testable: the filename formatting takes an explicit date and time zone so it
/// can be asserted deterministically.
public enum OutputPath {
    /// Native-style recording filename for a recording finished at `date`, e.g.
    /// "Screen Recording 2026-06-29 at 14.30.00.mov".
    public static func filename(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Screen Recording \(formatter.string(from: date)).mov"
    }

    /// Destination URL in the user's Downloads directory. Falls back to
    /// ~/Downloads if the system directory lookup ever fails.
    public static func downloadsURL(for date: Date, timeZone: TimeZone = .current) -> URL {
        let downloads = FileManager.default
            .urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads", isDirectory: true)
        return downloads.appendingPathComponent(filename(for: date, timeZone: timeZone))
    }
}
