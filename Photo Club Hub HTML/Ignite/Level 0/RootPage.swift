//
//  RootPage.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 27/05/2026.
//

import Ignite // for StaticPage

struct RootPage: StaticPage { // `path` intentionally omitted: Ignite always writes the homePage to index.html
    var title = "Photo Club Hub"
    var description: String { "Photo Club Hub website" }

    func body(context: PublishingContext) -> [BlockElement] {
        Text("Photo Club Hub")
            .font(.title1)
            .horizontalAlignment(.center)
            .margin(.vertical, .extraLarge)

        Text {
            Link("🇳🇱 (NL)", target: "/\(ExpertisesPage.relativePath(languageID: "nl"))")
                .linkStyle(.hover)
        }
            .font(.title1)
            .horizontalAlignment(.center)
        Text {
            Link("🇬🇧 (EN)", target: "/\(ExpertisesPage.relativePath(languageID: "en"))")
                .linkStyle(.hover)
        }
            .font(.title1)
            .horizontalAlignment(.center)
    }
}
