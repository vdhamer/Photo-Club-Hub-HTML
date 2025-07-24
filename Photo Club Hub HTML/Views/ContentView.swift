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
                                .foregroundStyle(.placeholder)
                                .font(.title2)
                        } else {
                            Text("\(club.fullName) (\(club.members.count))")
                                .font(.title2)
                        }
                    }
                }
            }

            detail: {
                Text(String(localized: "Please select a club in the sidebar.", table: "SwiftUI",
                            comment: "Message displayed when no club is selected"))
                .font(.title2)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 300, max: 600)
            .navigationSplitViewStyle(.balanced) // don't see a difference between .balanced and .prominentDetail

            Divider()
            HStack(alignment: .center) {
                Text("Records found:", tableName: "SwiftUI",
                     comment: "Label for stats shown at bottom of window")
                .font(.headline)
                Text("◼ \(allClubs.count) clubs", tableName: "SwiftUI",
                     comment: "Count of clubs in database Organization table")
                Text("◼ \(allOrganizations.count-allClubs.count) other organizations", tableName: "SwiftUI",
                     comment: "Count of non-clubs in database Organization table")
                Text("◼ \(allPhotographers.count) photographers", tableName: "SwiftUI",
                     comment: "Count of individuals in database Photographer table")
                Text("◼ \(allMembers.count) club memberships", tableName: "SwiftUI",
                     comment: "Count of members in database")
                Text("◼ \(allKeywords.count) expertise tags in use", tableName: "SwiftUI",
                     comment: "Count of expertises known in database")
                Text("◼ \(allPhotographerExpertises.count) expertise tags assigned", tableName: "SwiftUI",
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

                Button(String(localized: "Build Level1", table: "SwiftUI",
                              comment: "App button that generates HTML page listing all clubs")) {
                    print("Generating Level 1")
                    generateLevel1()
                }

                Button(String(localized: "Build Level2", table: "SwiftUI",
                              comment: "App button that generates HTML page listing all club members")) {
                    print("Generating Level 2")
                    generateLevel2()
                } .disabled(selectedClubIds.isEmpty ||
                            Organization.findCreateUpdate(context: viewContext,
                                                          organizationTypeEnum: OrganizationTypeEnum.club,
                                                          idPlus: OrganizationIdPlus(
                                                              id: [OrganizationID](selectedClubIds)[0],
                                                              nickname: "dummy")).members.isEmpty) // TODO

                Button(action: addClub, label: {
                    Label(String(localized: "Add Club", table: "SwiftUI", comment: "Button at top of UI"),
                          systemImage: "plus")
                })
            }
        }
    }

    fileprivate func addClub() { // when user presses Add Club button
        withAnimation {
            let newCount: Int = UserDefaults.standard.integer(forKey: "clubCounter") + 1
            UserDefaults.standard.set(newCount, forKey: "clubCounter") // increment value stored in User Defaults

            let organizationTypeEnum: OrganizationTypeEnum = OrganizationTypeEnum.club
            let town = "Eindhoven"
            let fullName = "Org #\(newCount)"
            let organizationIdPlus = OrganizationIdPlus(fullName: fullName, town: town, // OrganizationID part
                                                        nickname: "Nickname#\(newCount)")

            _ = Organization.findCreateUpdate(context: viewContext, // can be foreground of background context
                                              organizationTypeEnum: organizationTypeEnum,
                                              idPlus: organizationIdPlus,
                                              // real coordinates added in fgAnders.level2.json
                                              coordinates: CLLocationCoordinate2DMake(
                                                  Double.random(in: -180...180),
                                                  Double.random(in: -180...180)),
                                              optionalFields: OrganizationOptionalFields() // empty
            )

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use
                // this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
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
