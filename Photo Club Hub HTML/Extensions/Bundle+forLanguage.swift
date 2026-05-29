//
//  Bundle+forLanguage.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 28/05/2026.
//

import Foundation

extension Bundle {

    /// Returns the language-specific bundle for the given ISO 639-1 language code.
    ///
    /// Use this instead of `locale:` in `String(localized:)` when generating multilingual
    /// static HTML pages. Unlike `locale:`, which only affects number/date formatting,
    /// passing the language-specific bundle forces the correct translation to be loaded
    /// regardless of the development computer's language setting..
    ///
    /// - Parameter languageID: An ISO 639-1 language code (e.g. `"nl"`, `"en"`, `"de"`).
    ///   Must match the name of a `.lproj` directory compiled into the app bundle.
    /// - Returns: The `.lproj` bundle for the requested language, or `Bundle.main` if no
    ///   matching `.lproj` directory is found. The link to the an e.g. `en.lproj` directory may not be very relevant:
    ///   the returned bundle can be passed as a parameter to String() initalizsers to force the output language.
    static func forLanguage(_ languageID: String) -> Bundle {
        if let path = Bundle.main.path(forResource: languageID, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main // fallback: system language
    }
}
