//
//  TempRootPage.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 27/05/2026.
//

import Foundation // for Bundle
import Ignite // for StaticPage

struct TempRootPage: StaticPage { // `path` intentionally omitted: Ignite always writes the homePage to index.html
    var title = "Photo Club Hub"
    var description: String { "Photo Club Hub website" }

    /// Maps a languageID (e.g. "nl", "en") to the relative path the language link should point to.
    /// Injected so each Site (Level 0, Level 2, ...) can target a different landing page.
    let relativePath: (_ languageID: String) -> String

    func body(context: PublishingContext) -> [BlockElement] {
        Text("Photo Club Hub")
            .font(.title1)
            .horizontalAlignment(.center)
            .margin(.vertical, .extraLarge)

        Text {
            Link("🇳🇱 (NL)", target: "/\(relativePath("nl"))")
                .linkStyle(.hover)
        }
            .font(.title1)
            .horizontalAlignment(.center)
        Text {
            Link("🇬🇧 (EN)", target: "/\(relativePath("en"))")
                .linkStyle(.hover)
        }
            .font(.title1)
            .horizontalAlignment(.center)

        let textDevLang = String(localized: "Select your language preference.",
                                 table: "PhotoClubHubHTML.Ignite", // String shown in system language preference
                                 comment: "Language picker for the landing page")
        let textEnglish = String(localized: "Select your language preference.",
                                 table: "PhotoClubHubHTML.Ignite",
                                 bundle: Bundle.forLanguage("en"),
                                 comment: "Language picker for the landing page")

        Group {
            if textDevLang != textEnglish {
                Text {textDevLang}
            }
            Text { textEnglish }
        }
        .horizontalAlignment(.center)
        .padding(.vertical, .large)
    }
}
