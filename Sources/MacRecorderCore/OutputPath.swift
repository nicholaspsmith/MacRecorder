// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Nicholas Smith

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

    /// The user's Downloads directory, the default save location. Falls back
    /// to ~/Downloads if the system directory lookup ever fails.
    public static var downloadsDirectory: URL {
        FileManager.default
            .urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads", isDirectory: true)
    }

    /// Destination URL in the user's Downloads directory.
    public static func downloadsURL(for date: Date, timeZone: TimeZone = .current) -> URL {
        url(for: date, in: nil, timeZone: timeZone)
    }

    /// Destination URL in `directory`, the user's chosen save location. Falls
    /// back to Downloads when none is set or the folder no longer exists (an
    /// unplugged drive, a deleted folder), so a recording is never lost.
    public static func url(for date: Date, in directory: URL?, timeZone: TimeZone = .current) -> URL {
        var isDir: ObjCBool = false
        let folder = directory.flatMap {
            FileManager.default.fileExists(atPath: $0.path, isDirectory: &isDir) && isDir.boolValue ? $0 : nil
        } ?? downloadsDirectory
        return folder.appendingPathComponent(filename(for: date, timeZone: timeZone))
    }
}
