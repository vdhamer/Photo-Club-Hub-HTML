//
//  ContentView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI
import CoreData
import CoreLocation // for CLLocationCoordinate2DMake
import Photo_Club_Hub_Data // for Organization

struct ContentView: View {
    @Environment(\.managedObjectContext) fileprivate var viewContext

    // MARK: - @FetchRequests to get list of Clubs

    static let clubOnlyPredicate = NSPredicate(format: "organizationType_.organizationTypeName_= %@",
                                               argumentArray: [OrganizationTypeEnum.club.rawValue])
    static let allPredicate = NSPredicate(format: "TRUEPREDICATE")
    static let nonePredicate = NSPredicate(format: "FALSEPREDICATE")

    // MARK: - @FetchRequests to get lists and get counts

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Organization.fullName_, ascending: true)],
        predicate: allPredicate,
        animation: .default)
    fileprivate var allOrganizations: FetchedResults<Organization>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Organization.fullName_, ascending: true)],
        predicate: clubOnlyPredicate,
        animation: .default)
    fileprivate var allClubs: FetchedResults<Organization>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Photographer.familyName_, ascending: true)],
        predicate: allPredicate,
        animation: .default)
    fileprivate var allPhotographers: FetchedResults<Photographer>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)],
        predicate: allPredicate, // there is a variant of this FetchRequest in MembershipView.swift
        animation: .default)
    fileprivate var allMembers: FetchedResults<MemberPortfolio>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expertise.id_, ascending: true)],
        predicate: allPredicate,
        animation: .default)
    fileprivate var allKeywords: FetchedResults<Expertise> // duplicates Expertise.getAll()

    @FetchRequest(
        sortDescriptors: [],
        predicate: allPredicate,
        animation: .default)
    fileprivate var allPhotographerExpertises: FetchedResults<PhotographerExpertise>
    // MARK: - Body of ContentView

    @State private var selectedClubIds: Set<OrganizationID> = []

    var body: some View {
        VStack(alignment: .leading) {
            NavigationSplitView {
                List(allClubs, selection: $selectedClubIds) { club in
                    //                    ForEach(allClubs, id: \.self) { club in
                    NavigationLink {
                        MembershipView(club: club)
                    } label: {
                        if club.members.isEmpty {
                            Text(club.fullName)
                                .foregroundStyle(.gray) // was .placeholder
                                .font(.title2)
                        } else {
                            Text("\(club.fullName) (\(club.members.count))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.link)
                        }
                    }
                }
            }

            detail: {
                Text(String(localized: "Please select a club in the sidebar.",
                            table: "PhotoClubHubHTMLSwiftUI",
                            comment: "Message displayed when no club is selected"))
                .font(.title2)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 300, max: 600)
            .navigationSplitViewStyle(.balanced) // don't see a difference between .balanced and .prominentDetail

            Divider()
            HStack(alignment: .center) {
                Text("Records found:",
                     tableName: "PhotoClubHubHTMLSwiftUI",
                     comment: "Label for stats shown at bottom of window")
                .font(.headline)
                Text("◼ \(allClubs.count) clubs",
                     tableName: "PhotoClubHubHTMLSwiftUI",
                     comment: "Count of clubs in database Organization table")
                Text("◼ \(allOrganizations.count-allClubs.count) other organizations",
                     tableName: "PhotoClubHubHTMLSwiftUI",
                     comment: "Count of non-clubs in database Organization table")
                Text("◼ \(allPhotographers.count) photographers",
                     tableName: "PhotoClubHubHTMLSwiftUI",
                     comment: "Count of individuals in database Photographer table")
                Text("◼ \(allMembers.count) club memberships",
                     tableName: "PhotoClubHubHTMLSwiftUI",
                     comment: "Count of members in database")
                Text("◼ \(allKeywords.count) expertise tags in use",
                     tableName: "PhotoClubHubHTMLSwiftUI",
                     comment: "Count of expertises known in database")
                Text("◼ \(allPhotographerExpertises.count) expertise tags assigned",
                     tableName: "PhotoClubHubHTMLSwiftUI",
                     comment: "Count of how often expertises have been assigned to photographers")
            }
            .foregroundStyle(.secondary)
            .frame(height: 5)
        }

        .onAppear {
            NSWindow.allowsAutomaticWindowTabbing = false // disable tab bar (HackingWithSwift MacOS StormViewer)
        }
        .frame(minWidth: 480, minHeight: 290)
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {

                Button(String(localized: "Build Level 1 HTML",
                              table: "PhotoClubHubHTMLSwiftUI",
                              comment: "App button that generates HTML page listing all clubs")) {
                    print("Generating Level 1")
                    generateLevel1()
                }

                Button(String(localized: "Build Level 2 HTML",
                              table: "PhotoClubHubHTMLSwiftUI",
                              comment: "App button that generates HTML page listing all club members")) {
                    print("Generating Level 2")
                    generateLevel2()
                } .disabled(selectedClubIds.isEmpty || // no club selected
                            hasMembers(context: viewContext,  // selected club has no members
                                       clubID: [OrganizationID](selectedClubIds)[0]) == false)
           }
        }
    }

    // find club based on fullNameTown identifier and check if it has members
    fileprivate func hasMembers(context: NSManagedObjectContext, clubID: OrganizationID) -> Bool {
        do {
            let result: Bool
            try result = Organization.find(context: context, organizationID: clubID).members.isEmpty == false
            return result
        } catch {
            return false // if find(context:organizationID) can't find the club
        }
    }

    fileprivate func generateLevel1() { // index with all clubs

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level1.publishing"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        bgContext.performAndWait { // generate website
            let level1Site = Level1Site(moc: bgContext) // load data
            Task {
                do {
                    try await level1Site.publish() // generate HTML
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    fileprivate func generateLevel2() { // single club

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level2.publishing"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        bgContext.performAndWait { // generate website
            let level2Site = Level2Site(moc: bgContext) // load data
            Task {
                do {
                    try await level2Site.publish() // generate HTML
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

}

// #Preview {
//    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
// }
