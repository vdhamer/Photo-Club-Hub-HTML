//
//  TargetHost.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 14/03/2026.
//

import Foundation // for URL

/// Use `TargetHost` to select which base URL to use when generating links and assets.
/// The enum provides a small set of known environments (personal site, club site, local development).

/// Represents the alternative hosting environments for the generated HTML output.
///
/// The `localhost` case takes its port from ``SiteOutput/defaultPreviewPort``, the same constant the
/// built-in preview server starts from (#247), so the two cannot drift apart. The port reaches the
/// generated pages as `rel="canonical"`, `og:url`, `sitemap.xml` and `robots.txt` only — navigational
/// links are root-relative, so a preview served on a fallback port still browses correctly.
enum TargetHost: String, Codable, CaseIterable {
    /// Peter van den Hamer's personal website.
    case vdHamer
    /// Fotoclub De Gender's website.
    case fgDeGender
    /// Local development server, typically used during testing.
    case localhost

    /// The base URL for this host.
    var baseURL: URL {
        switch self {
        case Self.vdHamer: return URL(string: "http://www.vdhamer.com")!
        case Self.fgDeGender: return URL(string: "https://www.fcDeGender.nl")!
        // Deliberately the loopback form: what gets written into the generated site's `rel="canonical"`,
        // `og:url` and `sitemap.xml` should not carry the name of whichever Mac happened to generate it.
        case Self.localhost: return SiteOutput.previewURL(port: SiteOutput.defaultPreviewPort,
                                                          allowRemoteAccess: false)
        }
    }

    /// The base URL for a section of the site that is published under `path` on this host.
    ///
    /// Built from ``baseURL`` rather than from its own string literals, so the two cannot disagree about
    /// where a host lives.
    ///
    /// `localhost` ignores `path`. The published hosts serve this app's output from a subdirectory, but the
    /// preview server's document root *is* the generated site, so prefixing there would write a directory
    /// that does not exist into every `rel="canonical"`, `og:url` and `sitemap.xml` entry.
    func url(forPath path: String) -> URL {
        switch self {
        case Self.vdHamer, Self.fgDeGender: return baseURL.appending(path: path)
        case Self.localhost: return baseURL
        }
    }
}
