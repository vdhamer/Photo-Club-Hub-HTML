//
//  Level1Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import Ignite // for Site
import CoreData // for NSManagedObjectContext

/// Site configuration for the "Clubs" section (table listing  all Photo Clubs), generated with Ignite.
/// Defines the base URL, theme, metadata, and the Core Data–backed `Clubs` home page.
struct Level1Site: Site {

    let name: String = "Clubs"
    let url: URL
    let builtInIconsEnabled: BootstrapOptions = .none
    let author = "Peter van den Hamer"
    let homePage: Clubs
    let theme = MyTheme()

    init(moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        url = preferences.selectedHost.url(forPath: "clubs") ??
              URL(preferences.selectedHost.staticString)

        self.homePage = Clubs(moc: moc)
    }

}
