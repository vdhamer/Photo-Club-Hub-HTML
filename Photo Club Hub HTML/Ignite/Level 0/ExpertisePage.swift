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
    let title: String // page title shown in browser tab

    let expertiseID: String // canonical (=English) ID, e.g. "Architecture"

    // Plain-String snapshots taken on the moc's queue during init.
    // Reason: Ignite calls `description` and `body` from another queue, so reading
    // NSManagedObject properties there can crash with name_ == nil.
    let localizedName: String        // localized name (e.g. "Architectuur") or expertiseID ("Architecture") as fallback
    let localizedUsage: String?      // localized usage instructions for the expertise, nil if unavailable
    let hasLocalizedExpertise: Bool  // whether a LocalizedExpertise record exists for the specified language

    var path: String { "/\(ExpertisesPage.relativePath(languageID: languageID, expertiseID: expertiseID))" }
    var description: String { "List of photographers with \(expertiseLocal) expertise" }

    let languageID: String // ISO 639-1 code, e.g. "nl"

    // moc is reserved for photographer queries (issue #182)
    init(expertiseID: String, language: String, moc: NSManagedObjectContext) {
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
