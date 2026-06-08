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
/// One `ExpertisePage` is generated per (expertise, language) combination by `Level0Site`.
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
        let roleDescriptionOfClubTown: String // e.g. "Member of Fotoclub Klik, Eindhoven"
        let portfolioURL: URL? // links to portfolio on clubs own site
        let clubPageURL: URL? // links to the club's membership list page on this site
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
                        roleDescriptionOfClubTown: membership.roleDescriptionOfClubTown(
                            languageBundle: Bundle.photoClubHubDataModuleForLanguage(language)),
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

        // page title (showing which Expertise this page is about)
        Text(String(localized: "\(snapshot.localizedName) expertise (\(snapshot.photographerRows.count)x)",
                    table: "PhotoClubHubHTML.Ignite",
                    bundle: Bundle.forLanguage(languageID),
                    comment: "Heading at top of ExpertisePage showing expertise name and photographer count"))
            .font(.title1)
            .horizontalAlignment(.center)
            .margin(.top, .extraLarge)

        // sub-title (showing description of how the Expertise is supposed to be interpreted)
        expertiseDescriptionText()

        for row in snapshot.photographerRows { // generate row-by-row
            photographerRow(for: row)
        }

        // info about when the page was generated
        FooterText(languageID: languageID)
    }

    // MARK: - Row and cell views

    private func expertiseDescriptionText() -> Text {
        if snapshot.hasLocalizedExpertise {
            if let usage = snapshot.localizedUsage {
                return Text(usage)
                    .horizontalAlignment(.center)
            } else {
                return Text(String(localized: "Missing usage description for \(snapshot.localizedName)",
                                   table: "PhotoClubHubHTML.Ignite",
                                   bundle: Bundle.forLanguage(languageID),
                                   comment: "Missing usage warning near top op ExpertisePage"))
                    .horizontalAlignment(.center)
            }
        } else {
             return Text(String(
                        localized: "There is no description for \(expertiseID) because it is an unsupported expertise.",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: Bundle.forLanguage(languageID),
                        comment: "Missing usage description for an expertise"))
                .horizontalAlignment(.center)
        }
    }

    private func photographerRow(for row: PhotographerRow) -> Group {
        Group {
            Text {
                Span(row.name)
                if row.isDeceased {
                    Badge(MemberStatus.deceased.displayNameForAppUI)
                        .badgeStyle(.default)
                        .role(.secondary)
                        .margin(.leading, 10)
                }
            }
            .font(.title5)
            .margin(.top, .medium)
            .margin(.bottom, .small)

            Group {
                for cell in row.membershipCells {
                    membershipCell(for: cell)
                }
            }
            .style("display: flex", "flex-direction: row", "overflow-x: auto", "gap: 12px", "padding-bottom: 8px")
        }
        .padding()
        .background(Color(hex: "#F8F9FA")) // Bootstrap gray-100 aka near-white
        .cornerRadius(8)
        .style("border: 1px solid #DEE2E6") // Bootstrap gray-300 standard border color
        .margin(.bottom, .medium)
    }

    private func membershipCell(for cell: MembershipCell) -> Group {
        let thumbnailWidth = 175
        let cellPadding = 8
        let cellBorderWidth = 1
        let cellWidth = thumbnailWidth + 2 * cellPadding + 2 * cellBorderWidth
        return Group {
            Image(cell.thumbnailSrc, description: "portfolio thumbnail")
                .resizable()
                .aspectRatio(.square, contentMode: .fill)
                .cornerRadius(8)
                .frame(width: thumbnailWidth)
                .cursor(.pointer)
                .onClick { // image links to portfolio
                    let safePortfolio = cell.portfolioURL
                        ?? URL(string: MemberPortfolio.emptyPortfolioURL)
                        ?? URL(string: "https://www.google.com")!
                    CustomAction("window.location.href=\"\(safePortfolio)\";")
                }

            Text(cell.roleDescriptionOfClubTown) // caption links to club page
                .font(.body)
                .horizontalAlignment(.center)
                .margin(0)
                .padding(0)
                .cursor(.pointer)
                .onClick {
                    if let clubPageURL = cell.clubPageURL {
                        CustomAction("window.location.href=\"\(clubPageURL)\";")
                    }
                }
        }
        .style("width: \(cellWidth)px", "text-align: center", "flex-shrink: 0",
               "background-color: #FFFFFF", "border-radius: 6px", "padding: \(cellPadding)px",
               "border: \(cellBorderWidth)px solid #DEE2E6")
    }
}
