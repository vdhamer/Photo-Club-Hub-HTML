//
//  ExpertisePageSite.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 18/05/2026.
//

import Ignite // for Site
import CoreData // for NSManagedObjectContext

struct ExpertisePageSite: Site {
    var name: String
    var url: URL
    var builtInIconsEnabled: BootstrapOptions = .none
    var author = "Peter van den Hamer"
    let homePage: ExpertisePage
    var theme = MyTheme()

    init(expertiseID: String, language: String, moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        name = "\(language)/\(expertiseID)"
        url = preferences.selectedHost.url(directory: "\(language)/\(expertiseID)") ??
              URL(preferences.selectedHost.staticString)
        homePage = ExpertisePage(expertiseID: expertiseID, language: language, moc: moc)
    }
}
