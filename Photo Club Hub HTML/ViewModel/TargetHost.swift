//
//  TargetHost.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 14/03/2026.
//

import Foundation // for URL
import Photo_Club_Hub_Data // for Organization

/// Use `TargetHost` to select which base URL to use when generating links and assets.
/// The enum provides a small set of known environments (personal site, club site, local development).

/// Represents the alternative hosting environments for the generated HTML output.
///
/// the `staticString` value is the base URL string for that host.
enum TargetHost: String, Codable, CaseIterable {
    /// Peter van den Hamer's personal website.
    case vdHamer
    /// Fotoclub De Gender's website.
    case fgDeGender
    /// Local development server, typically used during testing.
    case localhost

    var staticString: StaticString {
        switch self {
        case Self.vdHamer: return "http://www.vdhamer.com"
        case Self.fgDeGender: return "https://www.fcDeGender.nl"
        case Self.localhost: return "http://localhost:8000"
        }
    }

    func url(directory: String) -> URL? {
        switch self {
        case Self.vdHamer: return URL(string: "http://www.vdhamer.com/\(directory)")
        case Self.fgDeGender: return URL(string: "https://www.fcDeGender.nl\(directory)")
        case Self.localhost: return URL(string: "http://localhost:8000") // no directory
        }
    }
}
