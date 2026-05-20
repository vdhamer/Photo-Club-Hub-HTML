//
//  ExpertisePageSite.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 18/05/2026.
//

import Ignite // for Site
import CoreData // for NSManagedObjectContext

struct ExpertisePageSite: Site {
    let name: String // used as og:site_name meta tag (shown by social media like Facebook when page is shared)
    let url: URL
    let builtInIconsEnabled: BootstrapOptions = .none
    let author = "Peter van den Hamer"
    let homePage: ExpertisePage
    let theme = MyTheme()

    init(expertiseID: String, language: String, moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        name = "Expertise: " + expertiseID
        url = preferences.selectedHost.url(directory: "\(language)/\(expertiseID)") ??
              URL(preferences.selectedHost.staticString)
        homePage = ExpertisePage(expertiseID: expertiseID, language: language, moc: moc)
    }
}
