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
    func generateLevel0(preferences: PreferencesStructHTML) -> [any Ignite::StaticPage] { // "::" needs Swift 6.4

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level0.generation"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        return bgContext.performAndWait { // generate website
            let level0Pages = Level0Pages(moc: bgContext, preferences: preferences) // actual loading of the data
            return level0Pages.pages
        }
    }

    @discardableResult
    func generateLevel1(preferences: PreferencesStructHTML) -> [any Ignite::StaticPage] { // '::' needs Swift 6.4

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level1.generation"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        return bgContext.performAndWait { // generate website
            let level1Pages = Level1Pages(moc: bgContext, preferences: preferences) // load data
            return level1Pages.pages
        }
    }

    /// Generates one Level 2 HTML page for each (club × language) combination.
    ///
    /// Delegates to `Level2Site`, which fetches all clubs and all languages from CoreData and creates
    /// one `Members` page per combination — but only for languages that have at least one
    /// `LocalizedExpertise` translation (keeping Level 2 output consistent with Level 0 expertise pages).
    /// All CoreData reads happen inside `performAndWait` on a dedicated background context.
    /// Publishing is not done here: ``publishAllLevels(preferences:)`` collects levels 0-2 and publishes them once.
    @discardableResult
    func generateLevel2(preferences: PreferencesStructHTML) -> [any Ignite::StaticPage] { // "::" needs Swift 6.4

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level2.generation"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true

        return bgContext.performAndWait {
            let level2Pages = Level2Pages(moc: bgContext, preferences: preferences)
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
    /// inline is `translateTownsAndCountries()` in ClubListView, kept separate for that reason (#246).
    ///
    /// Being `async` in a `nonisolated` extension is what keeps this off the main actor even though its caller
    /// is on it (SE-0338) — see the note above the extension for why that matters here.
    ///
    /// The translation counts are taken before any page is built. A sweep that is still running (from an earlier
    /// Generate, or from *Translate locations*) can add rows while the pages are being built, and adding is
    /// the only change possible. When counted **before**, the alert can at worst report a translation as on its way that
    /// a later level's pages already got. When counted **after**, it could report as present a translation that arrived
    /// too late for the pages, and say "All … locations are translated" about a site that lacks some (#271).
    ///
    /// - Returns: the `.succeeded` outcome for the completion alert: how many pages were written, the landing
    ///   page included, and how many town/country translations those pages hold (`completed`), still lack
    ///   (`waiting`) or show as "Town?" or "Country?" (`placeholders`). A failure is the throw, not a returned
    ///   `.failed`.
    /// - Throws: whatever Ignite's `publish()` throws. Unlike the per-level generators above, this does not
    ///   `ifDebugFatalError`: the failure is shown in an alert, and trapping in a debug build would stop the
    ///   alert ever being seen.
    func publishAllLevels(preferences: PreferencesStructHTML) async throws -> WebsiteGenerationOutcomeEnum {
        // Counted before any page is built, not after: see the note on translation counts above.
        let geocoding = LocalizedAddress.geocodingCounts( // own context: the view context belongs to the main actor
            context: PersistenceController.shared.container.newBackgroundContext())

        // Build each level's pages without publishing (sequential for now;
        // a later ticket can parallelize with a TaskGroup). Keep them as labeled groups so the
        // per-level structure stays visible into LevelAllSite (#217).
        let pageGroups: [PageGroup] = [
            PageGroup(label: "Level 0 – Expertises",
                      pages: generateLevel0(preferences: preferences)),
            PageGroup(label: "Level 1 – Organizations",
                      pages: generateLevel1(preferences: preferences)),
            PageGroup(label: "Level 2 – Members",
                      pages: generateLevel2(preferences: preferences))
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
        return .succeeded(pageCount: pageGroups.reduce(1) { $0 + $1.pages.count },
                          completed: geocoding.completed,
                          waiting: geocoding.waiting,
                          placeholders: geocoding.onErrorPlaceholders)
    }

}
