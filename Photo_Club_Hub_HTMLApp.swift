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
        OrganizationType.initConstants() // creates records for club, museum, and unknown
    }

    var body: some Scene {
        Window(String(localized: "Photo Club Hub HTML", table: "SwiftUI", comment: "Name of this macOS app"),
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

extension PhotoClubHubHtmlApp {

    static fileprivate func loadClubsAndMembers() {

        let viewContext = persistenceController.container.viewContext // "associated with the main application queue"
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.undoManager = nil // nil by default on iOS
        viewContext.shouldDeleteInaccessibleFaults = true
        // Clear CoreData database for simplicity and to trigger initConstants()
        Model.deleteAllCoreDataObjects(context: viewContext)

        // load list of keywords and languages from root.Level0.json file
        let level0BackgroundContext = makeBgContext(ctxName: "Level 0 loader")
        _ = Level0JsonReader(bgContext: level0BackgroundContext, isInTestBundle: false, useOnlyInBundleFile: false)

        // load list of photo clubs and museums from root.Level1.json file
        let level1BackgroundContext = makeBgContext(ctxName: "Level 1 loader")
        _ = Level1JsonReader(bgContext: level1BackgroundContext, // read root.Level1.json file
                             isInTestBundle: false, useOnlyInBundleFile: false)

        // load current/former members of Fotogroep De Gender
        let genderBackgroundContext = makeBgContext(ctxName: "Level 2 loader fgDeGender")
        _ = FotogroepDeGenderMembersProvider(bgContext: genderBackgroundContext,
                                             useOnlyInBundleFile: false)

        // load current/former members of Fotogroep Waalre
        let waalreBackgroundContext = makeBgContext(ctxName: "Level 2 loader fgWaalre")
        _ = FotogroepWaalreMembersProvider(bgContext: waalreBackgroundContext,
                                           useOnlyInBundleFile: false)

        // load current/former members of Fotoclub Bellus Imago
        let bellusBackgroundContext = makeBgContext(ctxName: "Level 2 loader fcBellusImago")
        _ = FotoclubBellusImagoMembersProvider(bgContext: bellusBackgroundContext,
                                               useOnlyInBundleFile: false)

        // load current/former members of Fotogroep Oirschot
        let oirschotBackgroundContext = makeBgContext(ctxName: "Level 2 loader fgOirschot")
        _ = FotogroepOirschotMembersProvider(bgContext: oirschotBackgroundContext,
                                             useOnlyInBundleFile: false)

        if includeXampleClubs {

            // load test member(s) of XampleMin. Club is called XampleMin (rather than ExampleMin) to be at end of list
            let xampleMinBackgroundContext = makeBgContext(ctxName: "Level 2 loader XampleMin")
            _ = XampleMinMembersProvider(bgContext: xampleMinBackgroundContext, useOnlyInBundleFile: false)

            // load test member(s) of XampleMax. Club is called XampleMax (rather than ExampleMax) to be at end of list
            let xampleMaxBackgroundContext = makeBgContext(ctxName: "Level 2 loader XampleMax")
            _ = XampleMaxMembersProvider(bgContext: xampleMaxBackgroundContext, useOnlyInBundleFile: false)

        }

        // load current/former members of Fotoclub Ericamera
        let ericameraBackgroundContext = makeBgContext(ctxName: "Level 2 loader fcEricamera")
        _ = FotoclubEricameraMembersProvider(bgContext: ericameraBackgroundContext, useOnlyInBundleFile: false)

    }

    static func makeBgContext(ctxName: String) -> NSManagedObjectContext {

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = ctxName
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?
        return bgContext

    }
}
