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

    @discardableResult
    func generateLevel0(preferences: PreferencesStructHTML,
                        publish: Bool = true) -> [any Ignite::StaticPage] { // index with all Expertises (Swift 6.4)

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level0.publishing"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        return bgContext.performAndWait { // generate website
            let level0Site = Level0Site(moc: bgContext, preferences: preferences) // load data
            if publish {
                Task {
                    do {
                        try await level0Site.publish() // generate HTML
                    } catch {
                        ifDebugFatalError("Publishing of results of Level0Site() failed. Error: \(error)")
                        print(error.localizedDescription)
                    }
                }
            }
            return level0Site.pages
        }
    }

    @discardableResult
    func generateLevel1(preferences: PreferencesStructHTML,
                        publish: Bool = true) -> [any Ignite::StaticPage] { // index with all clubs (Swift 6.4 syntax)

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level1.publishing"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        return bgContext.performAndWait { // generate website
            let level1Site = Level1Site(moc: bgContext, preferences: preferences) // load data
            if publish {
                Task {
                    do {
                        try await level1Site.publish() // generate HTML
                    } catch {
                        ifDebugFatalError("Publishing of results of Level1Site() failed. Error: \(error)")
                        print(error.localizedDescription)
                    }
                }
            }
            return level1Site.pages
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
                        publish: Bool = true) -> [any Ignite::StaticPage] { // all clubs × all languages (Swift 6.4)

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level2.publishing"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true

        return bgContext.performAndWait {
            let level2Site = Level2Site(moc: bgContext, preferences: preferences)
            if publish {
                Task {
                    do {
                        try await level2Site.publish()
                    } catch {
                        ifDebugFatalError("Publishing of results of Level2Site() failed. Error: \(error)")
                        print(error.localizedDescription)
                    }
                }
            }
            return level2Site.pages
        }
    }

    /// Generates the full website in a single `publish()` so that all three levels coexist in `Build/`.
    ///
    /// Each level's pages are built (with publishing bypassed) and concatenated into one `LevelAllSite`,
    /// which is published exactly once — so Ignite's `clearBuildFolder()` runs once and no level clobbers
    /// another's output. See issue #215.
    func generateLevelAll(preferences: PreferencesStructHTML) {
        // Build each level's pages without publishing (sequential for now;
        // a later ticket can parallelize with a TaskGroup).
        let level0Pages = generateLevel0(preferences: preferences, publish: false)
        let level1Pages = generateLevel1(preferences: preferences, publish: false)
        let level2Pages = generateLevel2(preferences: preferences, publish: false)

        // Single publish: one landing page + the three page arrays → one clearBuildFolder, no clobbering.
        let allSite = LevelAllSite(pages: level0Pages + level1Pages + level2Pages,
                                   preferences: preferences)
        Task {
            do {
                try await allSite.publish()
            } catch {
                ifDebugFatalError("Publishing of results of LevelAllSite() failed. Error: \(error)")
                print(error.localizedDescription)
            }
        }
    }

}
