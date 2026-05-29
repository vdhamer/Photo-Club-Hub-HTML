//
//  FooterText.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Foundation // for Date, TimeZone
import Ignite // for BlockElement, Alert

/// An Ignite localized footer showing the page's affiliation to Photo Club Hub and showing the creation timestamp.
///
/// Conforms to `BlockElement` so it can be placed directly inside a page's `@BlockElementBuilder body()` method.
/// A localized HTML page provides the required `languageID`when generating this FooterText.
struct FooterText: BlockElement {
    let languageID: String // ISO 639-1 code, e.g. "nl" — selects the translation bundle

    /// Claude came up with solution:
    /// Required by `PageElement` (via `BlockElement`). `FooterText` never applies CSS modifiers,
    /// so the getter returns a fresh default value borrowed from another element — the only way to
    /// obtain a `CoreAttributes` value outside the Ignite module, whose initializer is internal (in Ignite 0.6)
    /// The setter is intentionally discarded because mutations would be lost anyway (no stored backing).
    var attributes: CoreAttributes { get { Text("").attributes } set { _ = newValue } }

    /// Required by `BlockElement`. Governs how many grid columns this element occupies when placed
    /// inside a `Section`. `.automatic` lets Ignite decide based on context.
    var columnWidth: ColumnWidth = .automatic // not sure how to use this, but .automatic works ok

    func render(context: PublishingContext) -> String {
        let timezone = TimeZone.current
        let timezoneCode = timezone.abbreviation() ?? ""
        let timestamp: String = Date.now.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened, locale: Locale(identifier: languageID))
        )
        let appName = String(localized: "Photo Club Hub",
                             table: "PhotoClubHubHTML.Ignite",
                             bundle: Bundle.forLanguage(languageID),
                             comment: "The app name itself is localized here.'")

        let alert = Alert {
            Text { // this is Ignite's Text, not SwiftUI's Text
                String(localized: """
                                  This page is part of the \(appName) network \
                                  and was last updated on \(timestamp) \(timezoneCode).
                                  """,
                       table: "PhotoClubHubHTML.Ignite",
                       bundle: Bundle.forLanguage(languageID),
                       comment: "Timestamp at bottom of static HTML page showing whether page may be oudated.")
            }
            .horizontalAlignment(.center)
        }
        .margin(.top, .small)
        .margin(.bottom, .extraLarge)

        return alert.render(context: context)
    }

}
