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

    var name: String = "Clubs"
    // IMPORTANT: use https://www.fcDeGender.nl for localhost and use https://www.fcDeGender.nl/clubs/ for remote site
    var url: URL = URL("http://www.fcDeGender.nl")
//    var url: URL = URL("http://www.vdHamer.com/clubs/")
    var builtInIconsEnabled: BootstrapOptions = .none
    var author = "Peter van den Hamer"
    let homePage: Clubs
    var theme = MyTheme()

   init(moc: NSManagedObjectContext) {
        self.homePage = Clubs(moc: moc)
    }

}
