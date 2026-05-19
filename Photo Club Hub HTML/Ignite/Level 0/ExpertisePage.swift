//
//  ExpertisePage.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 18/05/2026.
//

import Ignite // for StaticPage
import CoreData // for NSManagedObjectContext

struct ExpertisePage: StaticPage {
    var title: String // page title shown in browser tab
    let expertiseID: String // English canonical ID, e.g. "Architecture"
    let language: String // ISO 639-1 code, e.g. "nl"

    // moc is reserved for photographer queries (issue #182)
    init(expertiseID: String, language: String, moc: NSManagedObjectContext) {
        self.expertiseID = expertiseID
        self.language = language
        self.title = expertiseID // TODO: localize per issue #182
    }

    func body(context: PublishingContext) -> [BlockElement] {
        Text("\(language)/\(expertiseID)")
            .font(.title1)
            .horizontalAlignment(.center)
            .margin(.top, .extraLarge)
    }
}
