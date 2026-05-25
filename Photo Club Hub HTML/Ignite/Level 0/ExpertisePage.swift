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

    let expertiseID: String // canonical (English) ID, e.g. "Architecture"
    let expertiseLocal: String // localized ID

    var path: String { "/\(languageID)/expertises/\(expertiseID)" } // e.g. "/en/expertises/Architecture/"
    var description: String { "List of photographers with \(expertiseLocal) expertise" }

    let languageID: String // ISO 639-1 code, e.g. "nl"

    // moc is reserved for photographer queries (issue #182)
    init(expertiseID: String, language: String, moc: NSManagedObjectContext) {
        self.languageID = language

        self.expertiseID = expertiseID
        let expertise = Expertise.find(context: moc, expertiseIdString: expertiseID)
        self.expertiseLocal = expertise?.selectedLocalizedExpertise(isoCode: language).localizedExpertise?.name ??
                              expertiseID // fallback is to show canonical string (e.g. for temporary Expertise)

        self.title = expertiseLocal
    }

    func body(context: PublishingContext) -> [BlockElement] {
        Text("\(expertiseLocal) expertise (\(languageID))")
            .font(.title1)
            .horizontalAlignment(.center)
            .margin(.top, .extraLarge)
    }
}
