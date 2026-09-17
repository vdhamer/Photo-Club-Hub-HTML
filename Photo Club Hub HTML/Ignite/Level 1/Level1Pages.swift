//
//  Level1Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import Ignite // for Site
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Language, LocalizedExpertise

/// Ignite `Site` that generates per-language index pages for both photo clubs and museums.
///
/// One `OrganizationsPage` is generated per OrganizationType (`.club`, `.museum`) for
/// every language that has at least one `LocalizedExpertise` translation.
struct Level1Pages: Site {

    let name: String = "Clubs"
    let url: URL // required by the Ignite `Site` protocol
    let builtInIconsEnabled: BootstrapOptions = .none
    let author = "Peter van den Hamer"
    let homePage: TempRootPage
    let theme = MyTheme()

    let pages: [any StaticPage] // precomputed to avoid Core Data queries on wrong thread

    init(moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        url = preferences.selectedHost.baseURL // e.g. "http://localhost:8000" or "https://www.fcdegender.nl"

        // inject a function defining where the RootPage language links navigate to
        self.homePage = TempRootPage(relativePath: { OrganizationsPage.relativePath(languageID: $0) })

        // The Data package knows which languages the project supports, so the generated pages and the
        // geocoder always work with the same set (Data#57). Sorted by ISO code, just to be deterministic.
        let languages = Photo_Club_Hub_Data.Language.supportedLanguages(context: moc)
        print("Generating Level 1 pages for languages: \(languages.map(\.isoCode))")

        var pageList: [any StaticPage] = []

        for language in languages {
            if language.isoCode != language.isoCode.lowercased() {
                ifDebugFatalError("Bad isoCode (not lowercase): \(language.isoCode)")
            }

            pageList.append(OrganizationsPage(moc: moc, organizationType: .club, language: language.isoCode))
            pageList.append(OrganizationsPage(moc: moc, organizationType: .museum, language: language.isoCode))
        }

        if pageList.isEmpty { ifDebugFatalError("No languages found in Level1Site.init()") }
        pages = pageList
    }

}
