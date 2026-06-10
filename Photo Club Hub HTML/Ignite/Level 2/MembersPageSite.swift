//
//  MembersPageSite.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 08/06/2026.
//

import Ignite // for Site
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Organization, Language

/// Ignite `Site` that generates one `Members` page per language for a single selected club.
///
/// Analogous to `Level0Site` which generates one `ExpertisePage` per (expertise × language), this site
/// generates the Level 2 member-list pages for the club identified by `preferences.selectedClubNickname`,
/// once per supported language. All pages are precomputed inside `init` (called within
/// `bgContext.performAndWait`) so that all CoreData reads happen on the correct queue before Ignite
/// renders on its own cooperative queue.
struct MembersPageSite: Site {

    let name: String = "Club members"
    let url: URL
    let builtInIconsEnabled: BootstrapOptions = .localBootstrap
    let author = "Peter van den Hamer"
    let homePage: ExpertiseRootPage // placeholder; homePage always writes to Build/index.html
    let theme = MyTheme()

    let pages: [any StaticPage] // precomputed to avoid Core Data queries on wrong threads

    /// Builds the set of member pages for the selected club across all languages.
    ///
    /// For the club identified by `preferences.selectedClubNickname`, one `Members` page is generated
    /// per language that exists in the database. Languages with a bad ISO code are skipped with a debug
    /// assertion. If the selected club cannot be found, no pages are generated and a debug assertion fires.
    ///
    /// - Parameters:
    ///   - moc: A `NSManagedObjectContext` whose queue this initializer must be called on.
    ///   - preferences: User settings; `selectedClubNickname` identifies the club, and other fields
    ///     control display options and target host.
    init(moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        url = preferences.selectedHost.url(forPath: preferences.selectedClubNickname) ??
              URL(preferences.selectedHost.staticString)

        self.homePage = ExpertiseRootPage()

        let languageFetch: NSFetchRequest<Photo_Club_Hub_Data.Language> = Photo_Club_Hub_Data.Language.fetchRequest()
        languageFetch.sortDescriptors = [NSSortDescriptor(key: "isoCode_", ascending: true)]
        let languages = (try? moc.fetch(languageFetch)) ?? []
        if languages.isEmpty { ifDebugFatalError("No languages found in MembersPageSite.init()") }

        var pageList: [any StaticPage] = []
        if let club = try? Organization.find(context: moc, nickname: preferences.selectedClubNickname) {
            for language in languages {
                if language.isoCode != language.isoCode.lowercased() {
                    ifDebugFatalError("Bad isoCode (not lowercase): \(language.isoCode)")
                }
                pageList.append(Members(moc: moc,
                                        club: club,
                                        languageID: language.isoCode,
                                        preferences: preferences))
            }
        } else {
            ifDebugFatalError("Club '\(preferences.selectedClubNickname)' not found in MembersPageSite.init()")
        }
        self.pages = pageList
    }

}
