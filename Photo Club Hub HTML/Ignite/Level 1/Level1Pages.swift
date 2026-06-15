//
//  Level1Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import Ignite // for Site
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Language, LocalizedExpertise

/// Ignite `Site` that generates a per-language index of photo clubs at `/{lang}/clubs/`.
///
/// One `ClubsPage` is generated for each language that has at least one `LocalizedExpertise` translation,
/// mirroring the guard used by `Level0Pages` and `Level2Pages`.
struct Level1Pages: Site {

    let name: String = "Clubs"
    let url: URL
    let builtInIconsEnabled: BootstrapOptions = .none
    let author = "Peter van den Hamer"
    let homePage: TempRootPage
    let theme = MyTheme()

    let pages: [any StaticPage] // precomputed to avoid Core Data queries on wrong thread

    init(moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        url = preferences.selectedHost.url(forPath: "clubs") ??
              URL(preferences.selectedHost.staticString)

        // inject a function defining where the RootPage language links navigate to
        self.homePage = TempRootPage(relativePath: { ClubsPage.relativePath(languageID: $0) })

        // get list of all language records in CoreData
        let languageFetch: NSFetchRequest<Photo_Club_Hub_Data.Language> = Photo_Club_Hub_Data.Language.fetchRequest()
        languageFetch.sortDescriptors = [NSSortDescriptor(key: "isoCode_", ascending: true)] // for determinism
        let languages = (try? moc.fetch(languageFetch)) ?? [] // below, we check indirectly if there are >0 languages

        var pageList: [any StaticPage] = []

        for language in languages {
            if language.isoCode != language.isoCode.lowercased() {
                ifDebugFatalError("Bad isoCode (not lowercase): \(language.isoCode)")
            }

            guard LocalizedExpertise.exists(context: moc, languageIsoCode: language.isoCode) else {
                print("""
                      Will not generate clubs page for \(language.isoCode.uppercased()) \
                      because there are no expertise translations in \(language.languageNameEN_ ?? language.isoCode).
                      """)
                continue // don't append languages without localized expertises
            }

            pageList.append(ClubsPage(moc: moc, language: language.isoCode))
        }

        if pageList.isEmpty { ifDebugFatalError("No languages found in Level1Site.init()") }
        pages = pageList
    }

}
