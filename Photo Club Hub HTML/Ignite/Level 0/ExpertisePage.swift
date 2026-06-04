//
//  ExpertisePage.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 18/05/2026.
//

import Ignite // for StaticPage (note: this imports Ignite.Language which is not Photo_Club_Hub_Data.Language)
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Expertise, Photographer, MemberPortfolio

/// An Ignite `StaticPage` that renders a single expertise tag's page in a single language.
///
/// Each page lists all photographers who have been tagged with a specific expertise (e.g. "Architecture"),
/// grouped by photographer. For each photographer, a row of clickable thumbnail images is shown —
/// one per club membership — each linking to the photographer's portfolio.
///
/// One `ExpertisePage` is generated per (expertise, language) combination by `ExpertisePageSite`.
/// The page path is derived from `ExpertisesPage.relativePath(languageID:expertiseID:)`.
struct ExpertisePage: StaticPage {
    var title: String { snapshot.localizedName } // page title shown in browser tab

    let expertiseID: String // canonical (=English) ID, e.g. "Architecture"
    let languageID: String  // ISO 639-1 code, e.g. "nl"

    // example for path value: "/en/expertises/Architecture" or "/nl/expertises/Architecture" - not "../Archtectuur"
    var path: String { "/\(ExpertisesPage.relativePath(languageID: languageID, expertiseID: expertiseID))" }
    // description populates the meta-tag called "name" in the HTML header
    var description: String { "List of photographers with \(snapshot.localizedName) expertise" }

    private struct MembershipCell {
        let clubName: String // clubs full name
        let portfolioURL: URL? // links to portfolio on clubs own site
        let clubPageURL: URL? // links to the club's membership list page on this stie
        let thumbnailSrc: String // either "/images/foo.jpg" (local) or "https://..." (remote)
    }

    private struct PhotographerRow {
        let name: String // name of photographer
        let isDeceased: Bool // still reachable?
        let membershipCells: [MembershipCell] // clubs that the photographer is or was associated with
    }

    private struct Snapshot {
        let localizedName: String // of Expertise tag
        let localizedUsage: String? // when to use Expertise tag
        let hasLocalizedExpertise: Bool // `temporary` expertises don't have translations
        let photographerRows: [PhotographerRow] // list of photographers with this expertise
    }

    private let snapshot: Snapshot

    // MARK: - init()

    // moc is used for Photographer queries to Core Data
    init(expertiseID: String, language: String, moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        self.languageID = language

        self.expertiseID = expertiseID
        let expertise = Expertise.find(context: moc, expertiseIdString: expertiseID)
        self.expertiseLocal = expertise?.selectedLocalizedExpertise(isoCode: language).localizedExpertise?.name ??
                              expertiseID // fallback is to show canonical string (e.g. for temporary Expertise)

        self.title = expertiseLocal
    }

    func body(context: PublishingContext) -> [BlockElement] {
        Text("\(expertiseLocal) expertise (\(languageID))")
            .font(.title1)
            .horizontalAlignment(.center)
            .margin(.top, .extraLarge)

        FooterText(languageID: languageID)
    }
}
