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
        let level0BackgroundContext = PersistenceController.shared.container.newBackgroundContext()
        level0BackgroundContext.name = "Level 0 loader"
        level0BackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        level0BackgroundContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?
        _ = Level0JsonReader(bgContext: level0BackgroundContext,
                             useOnlyInBundleFile: false)

        // load list of photo clubs and museums from root.Level1.json file
        let level1BackgroundContext = PersistenceController.shared.container.newBackgroundContext()
        level1BackgroundContext.name = "Level 1 loader"
        level1BackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        level1BackgroundContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?
        _ = Level1JsonReader(bgContext: level1BackgroundContext, // read root.Level1.json file
                             useOnlyInBundleFile: false)

        // load current/former members of Fotogroep De Gender
        let genderBackgroundContext = PersistenceController.shared.container.newBackgroundContext()
        genderBackgroundContext.name = "FG de Gender"
        genderBackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        genderBackgroundContext.automaticallyMergesChangesFromParent = true
        _ = FotogroepDeGenderMembersProvider(bgContext: genderBackgroundContext,
                                             useOnlyInBundleFile: false)

        // load current/former members of Fotogroep Waalre  // TODO renable clubs in Photo_Club_hub_HTMLApp.swift
//        let waalreBackgroundContext = PersistenceController.shared.container.newBackgroundContext()
//        waalreBackgroundContext.name = "Fotogroep Waalre"
//        waalreBackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//        waalreBackgroundContext.automaticallyMergesChangesFromParent = true
//        _ = FotogroepWaalreMembersProvider(bgContext: waalreBackgroundContext,
//                                           useOnlyInBundleFile: false)

        // load current/former members of Fotoclub Bellus Imago
//        let bellusBackgroundContext = PersistenceController.shared.container.newBackgroundContext()
//        bellusBackgroundContext.name = "Fotoclub Bellus Imago"
//        bellusBackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//        bellusBackgroundContext.automaticallyMergesChangesFromParent = true
//        _ = FotoclubBellusImagoMembersProvider(bgContext: bellusBackgroundContext,
//                                               useOnlyInBundleFile: false)

        if includeXampleClubs {

            // load test member(s) of XampleMin. Club is called XampleMin (rather than ExampleMin) to be at end of list
//            let xampleMinBackgroundContext = PersistenceController.shared.container.newBackgroundContext()
//            xampleMinBackgroundContext.name = "XampleMin"
//            xampleMinBackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//            xampleMinBackgroundContext.automaticallyMergesChangesFromParent = true
//            _ = XampleMinMembersProvider(bgContext: xampleMinBackgroundContext)

            // load test member(s) of XampleMax. Club is called XampleMax (rather than ExampleMax) to be at end of list
//            let xampleMaxBackgroundContext = PersistenceController.shared.container.newBackgroundContext()
//            xampleMaxBackgroundContext.name = "XampleMax"
//            xampleMaxBackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//            xampleMaxBackgroundContext.automaticallyMergesChangesFromParent = true
//            _ = XampleMaxMembersProvider(bgContext: xampleMaxBackgroundContext)

        }
    }
}
