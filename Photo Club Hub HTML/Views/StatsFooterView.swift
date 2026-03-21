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

    // MARK: - Body of RecordsFooterView

    var body: some View {
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
        }
        .foregroundStyle(.secondary)
        .frame(minWidth: 900, minHeight: 15)
    }
}

// MARK: - Preview of view

#Preview { // this preview actually works ;-)
    RecordsFooterView()
}
