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

    init(expertiseID: String, language: String, moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        self.languageID = language
        self.expertiseID = expertiseID
        // fill snapshot now to avoid accessing @MainActor-isolated `preferences` on a background thread
        self.snapshot = Self.makeSnapshot(expertiseID: expertiseID, language: language,
                                          moc: moc, useLocalThumbnails: preferences.useLocalThumbnails)
    }

    // All Core Data reads happen inside performAndWait so managed objects are touched
    // only on the moc's queue. Plain-value snapshots are returned for safe use on any thread.
    private static func makeSnapshot(expertiseID: String,
                                     language: String,
                                     moc: NSManagedObjectContext, useLocalThumbnails: Bool) -> Snapshot {
        moc.performAndWait {
            let expertise = Expertise.find(context: moc, expertiseIdString: expertiseID)
            let localizedExpertise = expertise?.selectedLocalizedExpertise(isoCode: language).localizedExpertise

            let fetchRequest: NSFetchRequest<PhotographerExpertise> = PhotographerExpertise.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "expertise_.id_ = %@", expertiseID)
            let photographerExpertises = (try? moc.fetch(fetchRequest)) ?? []

            let sortedPhotographers = photographerExpertises
                .map { $0.photographer }
                .sorted { $0.fullNameFirstLast < $1.fullNameFirstLast }

            let rows: [PhotographerRow] = sortedPhotographers.map { photographer in
                let sortedMemberships = photographer.memberships
                    .sorted { $0.organization.fullNameTown < $1.organization.fullNameTown }

                let membershipCells: [MembershipCell] = sortedMemberships.map { membership in
                    let thumbnailSrc: String
                    if useLocalThumbnails {
                        let localName = loadThumbnailToLocal(fullUrl: membership.featuredImageThumbnail)
                        thumbnailSrc = "/images/" + localName
                    } else {
                        thumbnailSrc = membership.featuredImageThumbnail.absoluteString
                    }
                    return MembershipCell(
                        clubName: membership.organization.fullNameTown,
                        portfolioURL: membership.level3URL_,
                        clubPageURL: membership.organization.level2URLDir,
                        thumbnailSrc: thumbnailSrc
                    )
                }

                return PhotographerRow(
                    name: photographer.fullNameFirstLast,
                    isDeceased: photographer.isDeceased,
                    membershipCells: membershipCells
                )
            }

            return Snapshot(localizedName: localizedExpertise?.name ?? expertiseID,
                            localizedUsage: localizedExpertise?.usage,
                            hasLocalizedExpertise: localizedExpertise != nil,
                            photographerRows: rows)
        }
    }

    // MARK: - Ignite body()

    func body(context: PublishingContext) -> [BlockElement] {
        Text("\(expertiseLocal) expertise (\(languageID))")
            .font(.title1)
            .horizontalAlignment(.center)
            .margin(.top, .extraLarge)

        FooterText(languageID: languageID)
    }
}
