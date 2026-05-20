//
//  Level0Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 10/10/2025.
//

import Ignite // for Site
import CoreData // for NSManagedObjectContext

struct Level0Site: Site {

    let name: String = "Expertises"
    // NOTE: http://www.fcDeGender.com works on localhost, http://www.fcDeGender.com/expertises works on remote site
    let url: URL
    let builtInIconsEnabled: BootstrapOptions = .none
    let author = "Peter van den Hamer"
    let homePage: Expertises
    let theme = MyTheme()

    init(moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        url = preferences.selectedHost.url(directory: "expertises") ??
              URL(preferences.selectedHost.staticString)

        self.homePage = Expertises(moc: moc)
    }

}
