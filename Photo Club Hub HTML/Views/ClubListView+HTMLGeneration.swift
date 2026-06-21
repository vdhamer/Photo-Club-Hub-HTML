//
//  ClubListView+HTMLGeneration.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI // this is a SwiftUI view
import CoreData // for FetchRequest?
import Photo_Club_Hub_Data // for Organization
@preconcurrency import Ignite // for StaticPage; SwiftUI symbols that clash with Ignite are qualified as SwiftUI.<Type>

extension ClubListView {

    // MARK: - page generation for individual levels

    @discardableResult
    func generateLevel0(preferences: PreferencesStructHTML,
                        publishImmediately: Bool = true) -> [any Ignite::StaticPage] { // "::" requires Swift 6.4

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level0.generation"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        return bgContext.performAndWait { // generate website
            let level0Pages = Level0Pages(moc: bgContext, preferences: preferences) // actual loading of the data

            if publishImmediately {
                Task {
                    do {
                        try await level0Pages.publish() // generate HTML
                    } catch {
                        ifDebugFatalError("Publishing of results of Level0Site() failed. Error: \(error)")
                        print(error.localizedDescription)
                    }
                }
            }

            return level0Pages.pages
        }
    }

    @discardableResult
    func generateLevel1(preferences: PreferencesStructHTML,
                        publishImmediately: Bool = true) -> [any Ignite::StaticPage] { // '::' requires Swift 6.4

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level1.generation"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        return bgContext.performAndWait { // generate website
            let level1Pages = Level1Pages(moc: bgContext, preferences: preferences) // load data
            if publishImmediately {
                Task {
                    do {
                        try await level1Pages.publish() // generate HTML
                    } catch {
                        ifDebugFatalError("Publishing of results of Level1Site() failed. Error: \(error)")
                        print(error.localizedDescription)
                    }
                }
            }
            return level1Pages.pages
        }
    }

    /// Generates one Level 2 HTML page for each (club × language) combination.
    ///
    /// Delegates to `Level2Site`, which fetches all clubs and all languages from CoreData and creates
    /// one `Members` page per combination — but only for languages that have at least one
    /// `LocalizedExpertise` translation (keeping Level 2 output consistent with Level 0 expertise pages).
    /// All CoreData reads happen inside `performAndWait` on a dedicated background context;
    /// Ignite's `publish()` is then called asynchronously via a `Task`.
    @discardableResult
    func generateLevel2(preferences: PreferencesStructHTML,
                        publishImmediately: Bool = true) -> [any Ignite::StaticPage] { // "::" syntac requires Swift 6.4

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level2.generation"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true

        return bgContext.performAndWait {
            let level2Pages = Level2Pages(moc: bgContext, preferences: preferences)
            if publishImmediately {
                Task {
                    do {
                        try await level2Pages.publish()
                    } catch {
                        ifDebugFatalError("Publishing of results of Level2Site() failed. Error: \(error)")
                        print(error.localizedDescription)
                    }
                }
            }
            return level2Pages.pages
        }
    }

    // MARK: - page generation for complete site

    /// Generates the full website in a single `publish()` so that all three levels coexist in `Build/`.
    ///
    /// Each level's pages are built (with publishing bypassed) and concatenated into one `LevelAllSite`,
    /// which is published exactly once — so Ignite's `clearBuildFolder()` runs once and no level clobbers
    /// another's output. See issue #215.
    func generateAllLevels(preferences: PreferencesStructHTML) {
        Task {
            // Build each level's pages without publishing (sequential for now;
            // a later ticket can parallelize with a TaskGroup). Keep them as labeled groups so the
            // per-level structure stays visible into LevelAllSite (#217).
            let pageGroups: [PageGroup] = [
                PageGroup(label: "Level 0 – Expertises",
                          pages: generateLevel0(preferences: preferences, publishImmediately: false)),
                PageGroup(label: "Level 1 – Organizations",
                          pages: generateLevel1(preferences: preferences, publishImmediately: false)),
                PageGroup(label: "Level 2 – Members",
                          pages: generateLevel2(preferences: preferences, publishImmediately: false))
            ]

            // Single publish: one landing page + the labeled groups → one clearBuildFolder, no clobbering.
            let allSite = CompleteSite(pageGroups: pageGroups, preferences: preferences)
            do {
                try await allSite.publish()
            } catch {
                ifDebugFatalError("Publishing of results of LevelAllSite() failed. Error: \(error)")
                print(error.localizedDescription)
            }

            // Geocoding depends on the Organization data as loaded in Levels 1 and.
            // It is slow (~5 min) due to throttling at the employed geolocation server.
            // So it runs automatically after publishing rather than blocking it.
            // Its LocalizedAddress rows show up as the localized Country/Town columns
            // on the next generate (see issue #219).
            // These columns may be only partially filled, but fil eventually.
            // CoreData is used as a cache to prevent unnecessary calls to the server.
            await OrganizationGeocoder().geocodeChangedAddresses()
        }
    }

}
