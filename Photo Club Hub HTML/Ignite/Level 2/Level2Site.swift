//
//  Level2Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import Ignite // for Site
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Organization, Language

/// Ignite `Site` that generates a series of `Members` pages: one per (club × language) combination.
///
/// All pages are precomputed inside `init` (called within `bgContext.performAndWait`) so that all CoreData
/// reads happen on the correct queue before Ignite renders on its own cooperative queue.
struct Level2Site: Site {

    let name: String = "Club members" // not too important: used in RSS and social media platforms
    let url: URL // The base URL for the site
    let builtInIconsEnabled: BootstrapOptions = .localBootstrap
    let author = "Peter van den Hamer"
    let homePage: TempRootPage // temporary placeholder; homePage always writes to Build/index.html
    let theme = MyTheme()

    let pages: [any StaticPage] // precomputed to avoid Core Data queries on wrong thread

    /// init() generates one `ExpertisePage` per (club × language), providing:
    ///  - that `language` has at least one `LocalizedExpertise`
    ///  - that `club` has at least one `MemberPortfolio` record
    ///
    /// If there are no clubs or no languages found, the debug mode app stops with a fatalError.
    ///
    /// - Parameters:
    ///   - moc: A `NSManagedObjectContext` whose queue this initializer must be called on.
    ///   - preferences: User settings; fields control display options and url of target host.
    init(moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        url = URL(preferences.selectedHost.staticString)

        // inject a function defining where the root page language links navigate to
        self.homePage = TempRootPage(relativePath: { languageID in
            ExpertisesPage.relativePath(languageID: languageID) }) // TODO this is answer for Level 0, not Level 2

        let clubType: String = OrganizationTypeEnum.club.rawValue // constant
        let clubsFetch: NSFetchRequest<Organization> = Organization.fetchRequest()
        // The fetch `.predicate` filters out non-club (now: Museum) organisations.
        // These would also be filtered out below when we generate pages for only Organizations
        // with at least one Member because Museums are not allowed to have Members.
        // But it is included here for clarity, safety (e.g. if new OrganizationTypes are added), and performance.
        clubsFetch.predicate = NSPredicate(format: "organizationType_.organizationTypeName_ = %@",
                                         argumentArray: [clubType])
        clubsFetch.sortDescriptors = [NSSortDescriptor(key: "nickName_", ascending: true)] // determinism only
        let clubs = (try? moc.fetch(clubsFetch)) ?? []

        let languageFetch: NSFetchRequest<Photo_Club_Hub_Data.Language> = Photo_Club_Hub_Data.Language.fetchRequest()
        languageFetch.sortDescriptors = [NSSortDescriptor(key: "isoCode_", ascending: true)] // determinism only
        let languages = (try? moc.fetch(languageFetch)) ?? []

        var pageList: [any StaticPage] = [] // we build the output here
        for language in languages {
            if language.isoCode != language.isoCode.lowercased() {
                ifDebugFatalError("Bad isoCode (not lowercase): \(language.isoCode)")
            }

            guard LocalizedExpertise.exists(context: moc, languageIsoCode: language.isoCode) else {
                print("""
                      Will not generate club pages for \(language.isoCode.uppercased()) \
                      because there are no expertise translations in \(language.languageNameEN_ ?? language.isoCode).
                      """)
                continue
            }

            for club in clubs {
                guard club.members.isEmpty == false else { continue } // skip clubs with no known members
                pageList.append(Members(moc: moc,
                                        club: club,
                                        languageID: language.isoCode,
                                        preferences: preferences))
            }
        } // outer loop for languages

        if pageList.isEmpty { ifDebugFatalError("No clubs or languages found in Level2Site.init()") }
        pages = pageList
    }

}
