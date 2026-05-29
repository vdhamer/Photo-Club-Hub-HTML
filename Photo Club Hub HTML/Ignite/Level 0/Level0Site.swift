//
//  Level0Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 10/10/2025.
//

import Ignite // for Site
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Expertise, Language

struct Level0Site: Site {

    let name: String = "Expertises"
    // NOTE: http://www.fcDeGender.com works on localhost, http://www.fcDeGender.com/expertises works on remote site
    let url: URL
    let builtInIconsEnabled: BootstrapOptions = .none
    let author = "Peter van den Hamer"
    let homePage: RootPage
    let theme = MyTheme()

    private let precomputedPages: [any StaticPage] // precomputed to avoid Core Data queries on wrong threads
    var pages: [any StaticPage] { return precomputedPages }

    init(moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        url = preferences.selectedHost.url(forPath: "expertises") ?? URL(preferences.selectedHost.staticString)

        self.homePage = RootPage()

        let expertiseFetch: NSFetchRequest<Expertise> = Expertise.fetchRequest()
        expertiseFetch.sortDescriptors = [NSSortDescriptor(key: "id_", ascending: true)]
        let expertises = (try? moc.fetch(expertiseFetch)) ?? [] // get all expertises
        if expertises.isEmpty { ifDebugFatalError("No expertises found in Level0Site.init()") }

        let languageFetch: NSFetchRequest<Photo_Club_Hub_Data.Language> = Photo_Club_Hub_Data.Language.fetchRequest()
        languageFetch.sortDescriptors = [NSSortDescriptor(key: "isoCode_", ascending: true)]
        let languages = (try? moc.fetch(languageFetch)) ?? []
        if languages.isEmpty { ifDebugFatalError("No languages found in Level0Site.init()") }

        var pages: [any StaticPage] = []
        for language in languages {
            var childPageCount = 0
            for expertise in expertises where LocalizedExpertise.exists(context: moc,
                                                                        expertiseID: expertise.id,
                                                                        languageIsoCode: language.isoCode) {
                // where-clause prevents generating pages without any localizedExpertises - even if Language exits.
                pages.append(ExpertisePage(expertiseID: expertise.id,
                                           language: language.isoCode.lowercased(),
                                           moc: moc))
                childPageCount += 1
            }
            if childPageCount > 0 { // no index page if there is nothing at all to see there
                pages.append(ExpertisesPage(moc: moc, language: language.isoCode.lowercased()))
            }
        }
        self.precomputedPages = pages
    }

}
