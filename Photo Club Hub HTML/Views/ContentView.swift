//
//  ContentView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

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
    private var allOrganizations: FetchedResults<Organization>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Organization.fullName_, ascending: true)],
        predicate: clubOnlyPredicate,
        animation: .default)
    private var allClubs: FetchedResults<Organization>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \OrganizationType.organizationTypeName_, ascending: true)],
        predicate: allPredicate,
        animation: .default)
    private var allOrganizationTypes: FetchedResults<OrganizationType>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Photographer.familyName_, ascending: true)],
        predicate: allPredicate,
        animation: .default)
    private var allPhotographers: FetchedResults<Photographer>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)],
        predicate: allPredicate, // there is a variant of this FetchRequest in MembershipView.swift
        animation: .default)
    private var allMembers: FetchedResults<MemberPortfolio>

    // MARK: - Body of ContentView

    var body: some View {
        VStack(alignment: .leading) {
            NavigationSplitView {
                List {
                    ForEach(allClubs, id: \.self) { club in
                        NavigationLink {
                            MembershipView(club: club)
                        } label: {
                            Text(club.fullName)
                                .font(.title2)
                        }
                    }
                    .onDelete(perform: deleteClubs)
                }
                .padding(.top)
                .navigationSplitViewColumnWidth(min: 200, ideal: 300, max: 600)
            } detail: {
                Text("Please select a club") // displayed
            }
            .navigationSplitViewStyle(.balanced) // don't see a difference between .balanced and .prominentDetail
            Divider()
            HStack(alignment: .center) {
                Text("Database content:").font(.headline)
                Text("◼ \(allOrganizationTypes.count) organizationTypes")
                Text("◼ \(allClubs.count) clubs")
                Text("◼ \(allOrganizations.count-allClubs.count) other organizations")
                Text("◼ \(allPhotographers.count) photographers")
                Text("◼ \(allMembers.count) club memberships")
            }
            .foregroundStyle(.secondary)
            .frame(height: 5)
        }
        .onAppear {
            NSWindow.allowsAutomaticWindowTabbing = false // disable tab bar (HackingWithSwift MacOS StormViewer)
            _ = Organization.addHardcodedFgDeGender(context: viewContext)
            _ = Organization.addHardcodedFgWaalre(context: viewContext)
        }
        .frame(minWidth: 480, minHeight: 290)
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {

                Button {
                    generateSite()
                } label: {
                    Label("Run Ignite", systemImage: "flame")
                }

                Button(action: addClub, label: {
                    Label("Add Club", systemImage: "plus")
                })
            }
        }
    }

    private func addClub() { // when user presses Add Club button
        withAnimation {
            let newCount: Int = UserDefaults.standard.integer(forKey: "clubCounter") + 1
            UserDefaults.standard.set(newCount, forKey: "clubCounter") // increment value stored in User Defaults

            let organizationTypeEnum: OrganizationTypeEnum = OrganizationTypeEnum.club
            let town = "Eindhoven"
            let fullName = "Org #\(newCount)"
            let organizationID = OrganizationID(fullName: fullName, town: town)
            let organizationIdPlus = OrganizationIdPlus(id: organizationID, nickname: "Nickname#\(newCount)")

            _ = Organization.findCreateUpdate(context: viewContext, // can be foreground of background context
                                              organizationTypeEnum: organizationTypeEnum,
                                              idPlus: organizationIdPlus,
                                              optionalFields: OrganizationOptionalFields()
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

    private func deleteClubs(at offsets: IndexSet) {
        withAnimation {
            for index in offsets { // probably only one
                let club = allClubs[index]
                viewContext.delete(club)
            }

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

    fileprivate func generateSite() {

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Ignite.publishing"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        bgContext.performAndWait { // generate website on background thread TODO this is still on the Main thread
            let memberSite = MemberSite(moc: bgContext) // load data
            Task {
                do {
                    try await memberSite.publish() // generate HTML
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

}

 #Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
 }
