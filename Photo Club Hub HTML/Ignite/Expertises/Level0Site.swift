//
//  Level0Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 10/10/2025.
//

import Ignite // for Site

import CoreData // for NSManagedObjectContext

struct Level0Site: Site {

    var name: String = "Expertises"
    // NOTE: http://www.fcDeGender.com works on localhost, http://www.fcDeGender.com/expertises works on remote site
    var url: URL = URL("http://www.fcDeGender.com")
    var builtInIconsEnabled: BootstrapOptions = .none
    var author = "Peter van den Hamer"
    let homePage: Expertises
    var theme = MyTheme()

   init(moc: NSManagedObjectContext) {
        self.homePage = Expertises(moc: moc)
    }

}
