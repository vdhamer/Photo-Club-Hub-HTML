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

    // MARK: - Core Data fetch requests

    static let clubOnlyPredicate = NSPredicate(format: "organizationType_.organizationTypeName_= %@",
                                               argumentArray: [OrganizationTypeEnum.club.rawValue])
    static let allPredicate = NSPredicate(format: "TRUEPREDICATE")
    static let nonePredicate = NSPredicate(format: "FALSEPREDICATE")

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Organization.fullName_, ascending: true)],
        predicate: allPredicate,
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

    // MARK: - Body of ContentView

    var body: some View {
        VStack(alignment: .leading) {
            NavigationSplitView {
                List {
                    ForEach(clubs, id: \.self) { club in // .fullName_ is not always unique
                        NavigationLink {
                            Text("""
                             \(club.organizationType.organizationTypeName.capitalized) \
                             \(club.fullName) (\(club.town))
                             """)
                        } label: {
                            Text(club.fullName)
                                .font(.headline)
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
                Text("Loaded records:").font(.headline)
                Text("   ◼ \(clubs.count) organizations")
                Text("   ◼ \(organizationTypes.count) organizationTypes")
                Text("   ◼ \(photographers.count) photographers")
                Text("   ◼ \(members.count) members")
            }
            .foregroundStyle(.secondary)
            .frame(height: 5)
        }
        .onAppear {
            NSWindow.allowsAutomaticWindowTabbing = false // disable tab bar (HackingWithSwift MacOS StormViewer)
            addTestMembers()
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

                Button(action: addClub, label: {
                    Label("Add Club", systemImage: "plus")
                })
            }
        }
    }

    // MARK: - add and delete clubs and members

    func addTestMembers() {
        let fgDeGender = ContentView.addFGdeGender()

        let hansKrüsemannPN = PersonName(givenName: "Hans", infixName: "", familyName: "Krüsemann")
        let hansKrüsemannPho = Photographer.findCreateUpdate(context: viewContext,
                                                  personName: hansKrüsemannPN,
                                                  optionalFields: PhotographerOptionalFields())
        let hansKrüsemannOpt = MemberOptionalFields(
            level3URL: URL(string: "http://www.vdhamer.com/fgDeGender/Hans_Krusemann/"),
            memberRolesAndStatus: MemberRolesAndStatus(role: [ .admin: true ], status: [:]),
            fotobondNumber: 1620090,
            membershipStartDate: "2016-04-01".extractDate(),
            membershipEndDate: nil)
        let hansKrüsemannMem = MemberPortfolio.findCreateUpdate(bgContext: viewContext,
                                                                organization: fgDeGender,
                                                                photographer: hansKrüsemannPho,
                                                                optionalFields: hansKrüsemannOpt)
        hansKrüsemannMem.refreshFirstImage()

        let jelleVanDeVoortPN = PersonName(givenName: "Jelle", infixName: "van de", familyName: "Voort")
        let jelleVanDeVoortPho = Photographer.findCreateUpdate(context: viewContext,
                                                  personName: jelleVanDeVoortPN,
                                                  optionalFields: PhotographerOptionalFields())
        let jelleVanDeVoortOpt = MemberOptionalFields(
            level3URL: URL(string: "http://www.vdhamer.com/fgDeGender/Jelle_van_de_Voort/"),
            memberRolesAndStatus: MemberRolesAndStatus(role: [ .chairman: true ], status: [:]),
            fotobondNumber: 1620103,
            membershipStartDate: "2020-01-01".extractDate(),
            membershipEndDate: nil)
        let jelleVanDeVoortMem = MemberPortfolio.findCreateUpdate(bgContext: viewContext,
                                                                organization: fgDeGender,
                                                                photographer: jelleVanDeVoortPho,
                                                                optionalFields: jelleVanDeVoortOpt)
        jelleVanDeVoortMem.refreshFirstImage()

        let peterVanDenHamerPN = PersonName(givenName: "Peter", infixName: "van den", familyName: "Hamer")
        let peterVanDenHamerPho = Photographer.findCreateUpdate(context: viewContext,
                                                  personName: peterVanDenHamerPN,
                                                  optionalFields: PhotographerOptionalFields(
                                                    bornDT: "1957-10-18".extractDate(),
                                                    photographerWebsite: URL(string: "https://glass.photo/vdhamer")
                                                  ))
        let peterVanDenHamerOpt = MemberOptionalFields(
            level3URL: URL(string: "http://www.vdhamer.com/fgDeGender/Peter_van_den_Hamer/"),
            memberRolesAndStatus: MemberRolesAndStatus(role: [ .admin: true ], status: [:]),
            fotobondNumber: 1620110,
            membershipStartDate: "2024-01-01".extractDate(),
            membershipEndDate: nil)
        let peterVanDenHamerMem = MemberPortfolio.findCreateUpdate(bgContext: viewContext,
                                                                organization: fgDeGender,
                                                                photographer: peterVanDenHamerPho,
                                                                optionalFields: peterVanDenHamerOpt)
        peterVanDenHamerMem.refreshFirstImage()
    }

    public static func addFGdeGender() -> Organization {
        withAnimation {
            let context = PersistenceController.shared.container.viewContext // foreground only for now
            let newCount = UserDefaults.standard.integer(forKey: "clubCounter") + 1
            UserDefaults.standard.set(newCount, forKey: "clubCounter")

            let organizationIdPlus = OrganizationIdPlus(fullName: "Fotogroep de Gender",
                                                        town: "Eindhoven",
                                                        nickname: "FGdeGender")

            let fgDeGender = Organization.findCreateUpdate(context: context, // foreground
                                                           organizationTypeEnum: OrganizationTypeEnum.club,
                                                           idPlus: organizationIdPlus,
                                                           optionalFields: OrganizationOptionalFields())
            do {
                try context.save()
                return fgDeGender
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use
                // this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func addClub() {
        withAnimation {
            let newCount = UserDefaults.standard.integer(forKey: "clubCounter") + 1
            UserDefaults.standard.set(newCount, forKey: "clubCounter")

            let organizationTypeEnum: OrganizationTypeEnum = OrganizationTypeEnum.randomClubMuseumUnknown()
            let town = "Eindhoven"
            let fullName = "Org #\(newCount)"
            let organizationID = OrganizationID(fullName: fullName, town: town)
            let organizationIdPlus = OrganizationIdPlus(id: organizationID, nickname: town)

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

}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
