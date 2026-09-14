//
//  SiteOutput.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 12/08/2026.
//

import Foundation // for URL, FileManager, NSHomeDirectory
import AppKit // for NSWorkspace
import SystemConfiguration // for SCDynamicStoreCopyLocalHostName

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

    /// Returns whether the site currently in ``buildDirectory`` was generated for ``TargetHost/localhost``.
    ///
    /// Only a localhost build can be previewed. The published hosts serve this app's output from a subdirectory, so
    /// their pages link root-relative *with* that prefix (`/hub/css/…`, `/hub/nl/clubs/`), while the preview
    /// server's document root is `Build/` itself, which has no `hub/` directory: the stylesheet and every link
    /// would come back 404.
    ///
    /// Read from the **build** rather than from the Settings, because the two can disagree: generate for localhost,
    /// then switch the target, and what is on disk is still previewable. `sitemap.xml` records the targeted host
    /// in every `<loc>`, and it survives a relaunch.
    ///
    /// Post-generation **reverse geocoding** does not change the answer. It writes to Core Data,
    /// for the next generate, and never touches `Build/`, so there is no reason to withhold the preview while it runs.
    ///
    /// Returns `false` when there is no build or no readable sitemap, which also covers a generate that failed after
    /// `publish()` had already cleared the directory.
    static func isGeneratedForLocalhost() -> Bool {
        let sitemap = buildDirectory.appending(path: "sitemap.xml")
        guard let text = try? String(contentsOf: sitemap, encoding: .utf8),
              let start = text.range(of: "<loc>"),
              let end = text.range(of: "</loc>", range: start.upperBound..<text.endIndex) else {
            return false
        }
        let firstLocation = text[start.upperBound..<end.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
        guard let generatedHost = URL(string: firstLocation)?.host() else { return false }
        return generatedHost == TargetHost.localhost.baseURL.host()
    }

    /// The port the built-in preview server tries first, and the one `TargetHost.localhost` bakes into the
    /// generated site. Matches Ignite's own `ignite run --port` default.
    static let defaultPreviewPort: UInt16 = 8000

    /// This Mac's Bonjour name, for previews that another device has to reach.
    ///
    /// A `.local` name is what survives being retyped on a phone, and it keeps working across DHCP changes
    /// where the LAN IP address does not.
    ///
    /// `SCDynamicStoreCopyLocalHostName` returns the *local host name*: the DNS-safe form macOS derives from
    /// the computer name, so `Peter's MacBook Air` arrives here as `Peters-MacBook-Air`. Do not substitute
    /// `Host.current().localizedName`, which is the computer name itself, spaces and apostrophes included.
    /// Falls back to `localhost` if the system has no local host name to give.
    static var bonjourHost: String {
        guard let localHostName = SCDynamicStoreCopyLocalHostName(nil) as String? else { return "localhost" }
        return "\(localHostName).local"
    }

    /// Where to point a browser at the site served by ``PreviewServer`` on `port`.
    ///
    /// The host has to match how the server bound, or the preview breaks on this Mac: a `.local` name resolves
    /// to `::1` here, which a listener bound only to `127.0.0.1` does not answer.
    ///
    /// - Parameter allowRemoteAccess: Mirrors `PreferencesStructHTML.allowRemotePreview`. When true the server
    ///   listens on every interface and this URL can be retyped on a phone; when false it is loopback only,
    ///   and `localhost` is both accurate and free of this Mac's name.
    static func previewURL(port: UInt16, allowRemoteAccess: Bool) -> URL {
        let host = allowRemoteAccess ? bonjourHost : "localhost"
        // The fallback is what makes the force-unwrap safe: it interpolates digits into a literal, nothing else.
        return URL(string: "http://\(host):\(port)") ?? URL(string: "http://localhost:\(port)")!
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
