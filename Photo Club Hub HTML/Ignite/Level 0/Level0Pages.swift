//
//  Level0Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 10/10/2025.
//

import Ignite // for Site
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Expertise, Language

/// Ignite `Site` (to become Pages) for the Level 0 ("Expertises") section of the generated static website.
///
/// Level 0 in this app's hierarchy is a utility layer of data: an index of all photographic expertises
/// (e.g. "Architecture", "Portrait") plus one detail page per (expertise × language) combination
/// where at least one translation exists for that language. Level 1 lists clubs, Level 2 lists
/// each club's members. Level 3 handles photos per member.
///
/// Pages are fully assembled inside `init` and stored in `precomputedPages` rather than computed
/// lazily by the `pages` getter. This is deliberate: Ignite renders on a concurrent cooperative
/// queue, and any Core Data access from there would violate `NSManagedObjectContext`'s
/// single-queue contract. By doing all fetches during `init` — which `LevelXListView` calls inside
/// `bgContext.performAndWait { }` — every NSManagedObject read happens on the moc's queue.
struct Level0Pages: Site {

    let name: String = "Expertises"
    // URL: local host example http://www.fcDeGender.com
    // URL: remote host example: http://www.fcDeGender.com/expertises
    let url: URL
    let builtInIconsEnabled: BootstrapOptions = .none
    let author = "Peter van den Hamer"
    let homePage: TempRootPage
    let theme = MyTheme()

    let pages: [any StaticPage] // precomputed to avoid Core Data queries on wrong threads

    /// Builds the full set of pages for the Level 0 site.
    ///
    /// For every language that has at least one `LocalizedExpertise` record, this generates:
    /// - one `ExpertisePage` per `Expertise` (both `isSupported` and `temporary` ones), and
    /// - one `ExpertisesPage` index linking to all ExpertisePages for that language.
    ///
    /// Pages are generated for *every* expertise rather than only the supported ones because the non-supported
    /// ("temporary") ones are actually shown in parts of the User Interface.
    /// Languages with zero translations are skipped entirely to avoid empty placeholder sub-sites.
    ///
    /// - Parameters:
    ///   - moc: A `NSManagedObjectContext` whose queue this initializer must be called on. The
    ///     caller is responsible for wrapping the call in `performAndWait` (or equivalent).
    ///   - preferences: User settings; currently used to pick the target host for absolute URLs.
    init(moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        url = preferences.selectedHost.url(forPath: "expertises") ?? URL(preferences.selectedHost.staticString)

        // inject a function defining where the root page language links navigate to
        self.homePage = TempRootPage(relativePath: { ExpertisesPage.relativePath(languageID: $0) })

        let expertiseFetch: NSFetchRequest<Expertise> = Expertise.fetchRequest()
        expertiseFetch.sortDescriptors = [NSSortDescriptor(key: "id_", ascending: true)]
        let expertises = (try? moc.fetch(expertiseFetch)) ?? [] // get all expertises
        if expertises.isEmpty { ifDebugFatalError("No expertises found in Level0Site.init()") }

        let languageFetch: NSFetchRequest<Photo_Club_Hub_Data.Language> = Photo_Club_Hub_Data.Language.fetchRequest()
        languageFetch.sortDescriptors = [NSSortDescriptor(key: "isoCode_", ascending: true)]
        let languages = (try? moc.fetch(languageFetch)) ?? []
        if languages.isEmpty { ifDebugFatalError("No languages found in Level0Site.init()") }

        var pageList: [any StaticPage] = []
        for language in languages { // de, en, fr, ... nl
            if language.isoCode != language.isoCode.lowercased() { // just a guard because violation → obscure behaviour
                ifDebugFatalError("Bad isoCode (not lowercase): \(language.isoCode)")
            }

            let languageHasTranslations = expertises.contains(where: { // result is a Bool
                LocalizedExpertise.exists(context: moc, expertiseID: $0.id, languageIsoCode: language.isoCode)
            })
            guard languageHasTranslations else { continue } // no ExpertisesPage for languages without any translations

            for expertise in expertises { // create pages for (language1,expertise1), (language1,expertise2), etc.
                pageList.append(ExpertisePage(expertiseID: expertise.id,
                                              language: language.isoCode,
                                              moc: moc,
                                              preferences: preferences))
            }
            pageList.append(ExpertisesPage(moc: moc,
                                           language: language.isoCode)) // links to all expertises in specified language
        }
        self.pages = pageList
    }

}
