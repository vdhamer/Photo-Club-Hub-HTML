//
//  ExpertisePage.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 18/05/2026.
//

import Ignite // for StaticPage (note: this imports Ignite.Language which is not Photo_Club_Hub_Data.Language)
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Expertise

struct ExpertisePage: StaticPage {
    let title: String // page title shown in browser tab

    let expertiseID: String // English canonical ID, e.g. "Architecture"
    let expertise: Expertise?

    let languageID: String // ISO 639-1 code, e.g. "nl"
    let language: Photo_Club_Hub_Data.Language? // qualified to avoid ambiguity with Ignite.Language

    // moc is reserved for photographer queries (issue #182)
    init(expertiseID: String, language: String, moc: NSManagedObjectContext) {
        self.languageID = language
        self.language = Photo_Club_Hub_Data.Language.find(context: moc, isoCode: language)

        self.expertiseID = expertiseID
        self.expertise = nil // TODO: fetch by expertiseID per issue #182
        self.title = expertiseID // TODO: localize per issue #182
    }

    func body(context: PublishingContext) -> [BlockElement] {
        Text("\(expertiseID) expertise (\(languageID))")
            .font(.title1)
            .horizontalAlignment(.center)
            .margin(.top, .extraLarge)
    }
}
