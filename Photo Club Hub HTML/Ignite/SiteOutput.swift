//
//  SiteOutput.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 12/08/2026.
//

import Foundation // for URL, FileManager, NSHomeDirectory
import AppKit // for NSWorkspace

/// Where the generated website ends up on disk.
///
/// The location isn't chosen here. Ignite's `URL.selectDirectories(from:)` walks up from the calling source
/// file looking for a `Package.swift`, finds none above this app's sources (this is an `.xcodeproj`, not a
/// package), and falls back to `NSHomeDirectory()` — the sandbox container. `PublishingContext` then appends
/// `buildDirectoryPath`, which defaults to `"Build"` and which this app never overrides.
///
/// This restates that outcome so the UI can show it and reveal it in Finder, and so the About window (#245)
/// and the completion popup (#246) can't drift apart. It does have to track the fork: if the fork's sandbox
/// branch changes, or if this app starts passing its own `buildDirectoryPath` to `publish()`, change it here.
enum SiteOutput {

    /// The directory that `publish()` writes the generated site into.
    static var buildDirectory: URL {
        URL(filePath: NSHomeDirectory()).appending(path: "Build")
    }

    /// Opens a Finder window showing the generated site.
    ///
    /// Falls back to the enclosing container directory when the site hasn't been generated yet, so the
    /// click always lands somewhere instead of doing nothing.
    static func revealInFinder() {
        let directory = buildDirectory
        let target = FileManager.default.fileExists(atPath: directory.path(percentEncoded: false))
            ? directory
            : directory.deletingLastPathComponent()
        NSWorkspace.shared.activateFileViewerSelecting([target])
    }

}
