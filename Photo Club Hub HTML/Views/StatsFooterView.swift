//
//  StatsFooterView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 21/03/2026.
//

import SwiftUI // for View
import Photo_Club_Hub_Data // for Organization

// MARK: - @FetchRequests to get lists and get counts

struct RecordsFooterView: View {
    @Environment(\.managedObjectContext) private var viewContext

    /// A geocoding sweep is in progress, as counted by ``ClubListView``, which starts them: show the ⏳.
    let isTranslating: Bool

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Organization.fullName_, ascending: true)],
        predicate: ClubListView.allPredicate)
    private var allOrganizations: FetchedResults<Organization>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Organization.fullName_, ascending: true)],
        predicate: ClubListView.clubOnlyPredicate)
    private var allClubs: FetchedResults<Organization>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Photographer.familyName_, ascending: true)],
        predicate: ClubListView.allPredicate)
    private var allPhotographers: FetchedResults<Photographer>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)],
        predicate: ClubListView.allPredicate)
    private var allMembers: FetchedResults<MemberPortfolio>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expertise.id_, ascending: true)],
        predicate: ClubListView.allPredicate)
    private var allKeywords: FetchedResults<Expertise>

    @FetchRequest(
        sortDescriptors: [],
        predicate: ClubListView.allPredicate)
    private var allPhotographerExpertises: FetchedResults<PhotographerExpertise>

    @FetchRequest(
        sortDescriptors: [],
        predicate: LocalizedAddress.allPredicate)
    private var allLocalizedAddresses: FetchedResults<LocalizedAddress> // not shown: makes body re-run, see below

    // MARK: - Body of RecordsFooterView

    /// Recounted on every run of body. What makes body run again while the geocoder works is the fetch of
    /// `allLocalizedAddresses`: every LocalizedAddress row the geocoder adds or updates changes that fetch, and
    /// reading it here makes sure SwiftUI counts this view as depending on it. Counting the rows themselves would
    /// not do: a club with changed coordinates keeps its old row but needs a new one.
    private var geocodingCounts: GeocodingCounts {
        _ = allLocalizedAddresses.count
        return LocalizedAddress.geocodingCounts(context: viewContext)
    }

    var body: some View {
        let geocoding = geocodingCounts // one count per run of body

        HStack(alignment: .center) {
            Text("Records found:",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Label for stats shown at bottom of window")
            .font(.headline)
            Text("◼ \(allClubs.count) clubs",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Count of clubs in database Organization table")
            Text("◼ \(allOrganizations.count-allClubs.count) other organizations",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Count of non-clubs in database Organization table")
            Text("◼ \(allPhotographers.count) photographers",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Count of individuals in database Photographer table")
            Text("◼ \(allMembers.count) club memberships",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Count of members in database")
            Text("◼ \(allKeywords.count) expertise tags in use",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Count of expertises known in database")
            Text("◼ \(allPhotographerExpertises.count) expertise tags assigned",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Count of how often expertises have been assigned to photographers")
            translatedLocations(geocoding)
        }
        .foregroundStyle(.secondary)
        .frame(minWidth: 900, minHeight: 15)
    }

    /// How far translating the town and country of every (organization × language) combination has got.
    ///
    /// - ⏳ "257 of 294 locations translated" while a sweep is running.
    /// - ⚠️ "2 of 294 locations untranslated" when the only gaps are stored "Town?"/"Country?" answers, which are
    ///   never asked again. The ⚠️ means what it means in the Generate alert (#271), whose sentence is the tooltip.
    /// - "294 locations translated" when nothing is missing.
    /// - "100 of 294 locations translated", without a symbol, when combinations without an answer remain and no
    ///   sweep is running: they were either not asked yet (new clubs before the next Generate) or failed during
    ///   the last sweep, and only the geocoder knows which, while it runs.
    @ViewBuilder
    private func translatedLocations(_ geocoding: GeocodingCounts) -> some View {
        if isTranslating {
            Text("◼ ⏳ \(geocoding.completed) of \(geocoding.total) locations translated",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Footer while town/country translations are being fetched: done so far, of all")
        } else if geocoding.waiting > 0 {
            Text("◼ \(geocoding.completed) of \(geocoding.total) locations translated",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Footer when some town/country translations are missing and none are being fetched")
        } else if geocoding.onErrorPlaceholders > 0 {
            Text("◼ ⚠️ \(geocoding.onErrorPlaceholders) of \(geocoding.total) locations untranslated",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Footer when the only missing town/country translations are ones that cannot be translated")
                .help(String(localized: """
                                 \(geocoding.onErrorPlaceholders) locations cannot be translated \
                                 and will continue to show “Town?” or “Country?”.
                                 """,
                             table: "PhotoClubHubHTML.SwiftUI",
                             comment: "Alert sentence: translations that will stay as placeholders"))
        } else {
            Text("◼ \(geocoding.total) locations translated",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Footer when every organization has its town/country translated in every language")
        }
    }
}

// MARK: - Preview of view

#Preview {
    RecordsFooterView(isTranslating: false)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
