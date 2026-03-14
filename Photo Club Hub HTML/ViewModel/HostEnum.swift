//
//  TargetHost.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 14/03/2026.
//

/// Use `TargetHost` to select which base URL to use when generating links and assets.
/// The enum provides a small set of known environments (personal site, club site, local development).

/// Represents the alternative hosting environments for the generated HTML output.
///
/// The raw value is the base URL string for that host.
enum TargetHost: String, CaseIterable {
    /// Peter van den Hamer's personal website.
    case vdHamer = "http://www.vdhamer.com"
    /// Fotoclub De Gender's public website.
    case fgDeGender = "https://www.fcDeGender.nl"
    /// Local development server, typically used during testing.
    case localhost = "http://localhost:8000"
}
