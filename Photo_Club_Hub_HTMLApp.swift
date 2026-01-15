//
//  Photo_Club_Hub_HTMLApp.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI
import Ignite
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for *MemberProvider struct

@main
struct PhotoClubHubHtmlApp: App {
    static let includeXampleClubs: Bool = true // whether or not to include XmpleMin and XmpleMax clubs
    static let persistenceController = PersistenceController.shared // for Core Data

    init() {
        // Core Data settings
        let persistenceController = PersistenceController.shared // for Core Data
        let viewContext = persistenceController.container.viewContext // "associated with the main application queue"
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.undoManager = nil // nil by default on iOS
        viewContext.shouldDeleteInaccessibleFaults = true

        OrganizationType.initConstants(context: viewContext) // creates records for club, museum, and unknown
    }

    var body: some Scene {
        Window(String(localized: "Photo Club Hub HTML",
                      table: "PhotoClubHubHTML.SwiftUI",
                      comment: "Name of this macOS app"),
               id: "mainWindow") {
            ContentView()
                .environment(\.managedObjectContext, Self.persistenceController.container.viewContext)
                .onAppear {
                    Self.loadClubsAndMembers()
               }
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .undoRedo) { }
            CommandGroup(replacing: .help) { }
            CommandGroup(replacing: .systemServices) { }
            CommandGroup(replacing: .pasteboard) { } // Suppresses Apple Intelligence's Writing Tools in the menu
        }
    }
}

private let isBeingTested = false // these are being loaded to get the data into Core Data, not for testing purposes

extension PhotoClubHubHtmlApp {

    // swiftlint:disable:next function_body_length
    static private func loadClubsAndMembers() {
        let useOnlyInBundleFile: Bool = false

        let viewContext = persistenceController.container.viewContext // "associated with the main application queue"
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.undoManager = nil // nil by default on iOS
        viewContext.shouldDeleteInaccessibleFaults = true

        // Clear CoreData database for simplicity and to trigger initConstants()
        Model.deleteAllCoreDataObjects(viewContext: viewContext)

	// MARK: - Level 0

        // load list of Expertises and Languages from root.Level0.json file
        _ = Level0JsonReader(
            bgContext: makeBgContext(ctxName: "Level 0 loader"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // MARK: - Level 1

	// load list of photo clubs and museums from root.Level1.json file
        _ = Level1JsonReader(
            bgContext: makeBgContext(ctxName: "Level 1 loader for root"),
            fileName: "root_",
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // MARK: - Level 2

        // load current/former members of Fotogroep De Gender
        _ = FotogroepDeGenderMembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader fgDeGender"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load current/former members of Fotogroep Waalre
        _ = FotogroepWaalreMembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader fgWaalre"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load current/former members of Fotoclub Bellus Imago
        _ = FotoclubBellusImagoMembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader fcBellusImago"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load current/former members of Fotogroep Oirschot
        _ = FotogroepOirschotMembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader fgOirschot"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load test member(s) of XampleMin. Club name starts with an X in order to be at end of list
        _ = XampleMinMembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader XampleMin"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load test member(s) of XampleMax. Club name starts with an X in order to be at end of list
        _ = XampleMaxMembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader XampleMax"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load current/former members of container for Persoonlijke members of Fotobond (in region 16)
        _ = Persoonlijk16MembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader Persoonlijk16"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load current/former members of Fotoclub Ericamera
        _ = FotoclubEricameraMembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader fcEricamera"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load current/former members of Fotoclub Den Dungen
        _ = FotoclubDenDungenMembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader fcDenDungen"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load current/former members of Fotokring Sint-Michielsgestel
        _ = FotokringStMichielsgestelMembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader fkGestel"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load current/former members of container for Persoonlijke members of Fotobond (in region 03)
        _ = Persoonlijk03MembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader Persoonlijk03"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // load current/former members of Fotoclub Veghel
        _ = FotoclubVeghelMembersProvider(
            bgContext: makeBgContext(ctxName: "Level 2 loader fcVeghel"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

    }

    static func makeBgContext(ctxName: String) -> NSManagedObjectContext {

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = ctxName
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?
        return bgContext

    }
}
