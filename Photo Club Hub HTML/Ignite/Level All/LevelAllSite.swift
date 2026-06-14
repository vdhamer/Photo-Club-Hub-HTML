//
//  LevelAllSite.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 14/06/2026.
//

import Ignite // for Site
import Foundation // for URL
import Photo_Club_Hub_Data // for ClubsPage.relativePath language target

/// Single Ignite `Site` published once so all three levels' pages coexist in one `Build/` tree (#215).
///
/// Pages are supplied pre-built by the caller (the Level 0/1/2 generators with publishing bypassed);
/// the only page this site owns is the shared landing page. Because `publish()` is called exactly once,
/// Ignite's `clearBuildFolder()` runs once and no level clobbers another's output.
struct LevelAllSite: Site {

    let name = "Photo Club Hub"
    let url: URL
    let builtInIconsEnabled: BootstrapOptions = .none // no Bootstrap icons used; expertise markers are emoji
    let author = "Peter van den Hamer"
    let homePage: TempRootPage
    let theme = MyTheme()

    let pages: [any StaticPage]

    init(pages: [any StaticPage], preferences: PreferencesStructHTML) {
        url = URL(preferences.selectedHost.staticString)
        // single landing page; its language buttons link to /<lang>/clubs/ (same as Level1Site)
        homePage = TempRootPage(relativePath: { ClubsPage.relativePath(languageID: $0) })
        self.pages = pages
    }

}
