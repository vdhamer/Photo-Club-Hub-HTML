//
//  CompleteSite.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 14/06/2026.
//

import Ignite // for Site
import Foundation // for URL
import Photo_Club_Hub_Data // for ClubsPage.relativePath language target

/// A labeled group of pre-built pages, kept separate so the per-level
/// structure stays visible inside `LevelAllSite` and can be reported on (page counts per page group).
/// Extensible beyond the current levels — e.g. with a future "Level 1 -  Museums" group is just another value.
struct PageGroup {
    let label: String // e.g. "Level 0 - Expertises"
    let pages: [any StaticPage] // to hold all the pages in the PageGroup (e.g. for 30 expertises x 2 languages)
}

/// Single Ignite `Site` published once so all three levels' pages coexist in one `Build/` tree (#215).
///
/// Pages are supplied pre-built by the caller (the Level 0/1/2 generators with the publishing step bypassed)
/// as labeled `PageGroup`s; the only page this site owns is the shared landing page. Because
/// `publish()` is called exactly once, Ignite's `clearBuildFolder()` runs once and the levels don't
/// clobber each other's output pages.
struct CompleteSite: Site {

    let name = "Photo Club Hub"
    let url: URL
    var favicon: URL? { URL(string: "/favicon.png") }
    let builtInIconsEnabled: BootstrapOptions = .none // no Bootstrap icons used; expertise markers are emoji
    let author = "Peter van den Hamer"
    let homePage: TempRootPage
    let theme = MyTheme()

    private let pageGroups: [PageGroup] // kept for future per-group reporting (page counts per level)
    // Ignite's `Site.pages` carries a @PageBuilder; satisfy it with a stored (non-builder) property,
    // flattened once from pageGroups in init while preserving group order.
    let pages: [any StaticPage]

    /// Creates the combined site from the labeled page groups that the Level 0/1/2 generators pre-built.
    ///
    /// The resulting `LevelAllSite` is a fully-configured Ignite `Site` — its `url`, `homePage`, and
    /// `pageGroups` are populated — ready to be published exactly so all levels share one `Build/` tree.
    /// - Parameters:
    ///   - pageGroups: The pre-built page groups from the various levels, published together so a single
    ///     `publish()` (and its one `clearBuildFolder()`) lets them coexist in `Build/` without clobbering.
    ///   - preferences: Site-wide settings; `selectedHost` supplies the deployment base URL, and the
    ///     landing page's language buttons follow the same `/<lang>/clubs/` scheme as `Level1Pages`.
    init(pageGroups: [PageGroup], preferences: PreferencesStructHTML) {
        url = URL(preferences.selectedHost.staticString)
        // single landing page; its language buttons link to /<lang>/clubs/ (same as Level1Pages)
        homePage = TempRootPage(relativePath: { OrganizationsPage.relativePath(languageID: $0) })
        self.pageGroups = pageGroups
        pages = pageGroups.flatMap(\.pages) // Site protocol expects [any StaticPage] that needs publishing
    }

}
