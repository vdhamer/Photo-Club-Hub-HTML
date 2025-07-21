//
//  Level1Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import Ignite // for Site

import SwiftUI // for @State
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Organization

struct Level1Site: Site {

    var name: String = "Clubs"
    // IMPORTANT: http://www.vdhamer.com gives localhost result, http://www.vdhamer.com/clubs works on remote site
    var url: URL = URL("http://www.vdhamer.com")
    var builtInIconsEnabled: BootstrapOptions = .none
    var author = "Peter van den Hamer"
    let homePage: Clubs
    var theme = MyTheme()

   init(moc: NSManagedObjectContext) {
        self.homePage = Clubs(moc: moc)
    }

}
