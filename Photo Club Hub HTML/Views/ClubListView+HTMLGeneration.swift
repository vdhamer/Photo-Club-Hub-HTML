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

// Everything here is `nonisolated`, and that is load-bearing rather than tidiness. `View` is `@MainActor`, so
// without it these methods inherit the main actor — and `generateLevelN` block their thread inside
// `performAndWait`, which would mean generating the site on the main thread with the window frozen and the
// progress spinner unable to draw a single frame (#246).
nonisolated extension ClubListView {

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
    ///
    /// Returning only when `publish()` has returned is the point: it lets the caller take its spinner down and
    /// raise the completion alert at the moment the site is on disk. The reverse-geocoding that used to follow
    /// inline is ``geocodeAfterGeneration()``, kept separate for that reason (#246).
    ///
    /// Being `async` in a `nonisolated` extension is what keeps this off the main actor even though its caller
    /// is on it (SE-0338) — see the note above the extension for why that matters here.
    ///
    /// - Returns: how many pages were written, the landing page included.
    /// - Throws: whatever Ignite's `publish()` throws. Unlike the per-level generators above, this does not
    ///   `ifDebugFatalError`: the failure is shown in an alert, and trapping in a debug build would stop the
    ///   alert ever being seen.
    func publishAllLevels(preferences: PreferencesStructHTML) async throws -> Int {
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
        try await allSite.publish()

        // Counted from what was handed to CompleteSite rather than by listing Build/, which also holds css/,
        // images/ and the feed. The 1 is the landing page CompleteSite owns and adds to the groups' pages.
        //
        // One total, not a per-level breakdown: the labels above would make one nearly free, but the record
        // counter in RecordsFooterView is where per-level numbers already live, and a second set in the
        // completion alert would only duplicate them or quietly disagree (#246).
        return pageGroups.reduce(1) { $0 + $1.pages.count }
    }

    /// Reverse-geocodes the addresses that changed, after a generate has finished.
    ///
    /// Geocoding depends on the Organization data as loaded in Levels 1 and 2.
    /// It is slow (~5 min) due to throttling at the employed geolocation server.
    /// So it runs after publishing rather than blocking it.
    /// Its LocalizedAddress rows show up as the localized Country/Town columns
    /// on the next generate.
    /// These columns may be only partially filled, but fill eventually.
    /// CoreData is used as a cache to prevent unnecessary calls to the server.
    ///
    /// Deliberately unreported: the running record counter in `RecordsFooterView` already moves while this
    /// works, and the results are persisted, so there is nothing the user has to wait for or act on (#246).
    func geocodeAfterGeneration() async {
        await OrganizationGeocoder().geocodeChangedAddresses()
    }

}
