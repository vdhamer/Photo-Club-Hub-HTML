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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Organization.fullName_, ascending: true)],
        predicate: NSPredicate(value: true), // doesn't do anything yet (should filter on Clubs)
        animation: .default)
    private var clubs: FetchedResults<Organization>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \OrganizationType.organizationTypeName_, ascending: true)],
        predicate: NSPredicate(value: true), // doesn't do anything yet (should filter on Clubs)
        animation: .default)
    private var organizationTypes: FetchedResults<OrganizationType>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Photographer.familyName_, ascending: true)],
        predicate: NSPredicate(value: true), // doesn't do anything yet (should filter on Clubs)
        animation: .default)
    private var photographers: FetchedResults<Photographer>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)],
        predicate: NSPredicate(value: true), // doesn't do anything yet (should filter on Clubs)
        animation: .default)
    private var members: FetchedResults<MemberPortfolio>

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(clubs, id: \.self) { club in // .fullName_ is not always unique
                    NavigationLink {
                        Text(club.fullName_ ?? "No name")
                    } label: {
                        Text(club.fullName_ ?? "No name")
                    }
                }
                .onDelete(perform: deleteClubs)
                Divider()
                Text("\(clubs.count) organizations")
                Text("\(organizationTypes.count) organizationTypes")
                Text("\(photographers.count) photographers")
                Text("\(members.count) members")
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 300, max: 300)
        } detail: {
            Text("Please select a club") // displayed
        }
        .navigationSplitViewStyle(.balanced) // don't see a difference between .balanced and .prominentDetail
        .onAppear {
            NSWindow.allowsAutomaticWindowTabbing = false // disable tab bar (HackingWithSwift MacOS StormViewer)
        }
        .frame(minWidth: 480, minHeight: 290)
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {

                Button {
                    let memberSite = MemberSite() // load data

                    Task(priority: .userInitiated) {
                        do {
                            try await memberSite.publish() // generate HTML
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                } label: {
                    Label("Run Ignite", systemImage: "flame")
                }

                Button(action: addClub) { Label("Add Club", systemImage: "plus") }
            }
        }
    }

    private func addClub() {
        withAnimation {
            let club = Organization(context: viewContext)
            let newCount = UserDefaults.standard.integer(forKey: "clubCounter") + 1
            UserDefaults.standard.set(newCount, forKey: "clubCounter")

            let random: Bool = .random() // 50% club, 50% museum
            club.organizationType_ = OrganizationType.findCreateUpdate(context: viewContext,
                                                                       organizationTypeName: random ? "museum" : "club")

            club.town_ = "Eindhoven"
            club.fullName_ = """
                             Organization \(newCount) \
                             (\(club.town_!)) \
                             of type \(club.organizationType_!.organizationTypeName.capitalized)
                             """

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
                let club = clubs[index]
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

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = 2
        formatter.maximumFractionDigits = 0

        return formatter
    }()
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
