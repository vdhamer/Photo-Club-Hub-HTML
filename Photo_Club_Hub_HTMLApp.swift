//
//  Photo_Club_Hub_HTMLApp.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI
import Ignite

@main
struct PhotoClubHubHtmlApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        OrganizationType.initConstants() // creates records for club, museum, and unknown
    }

    var body: some Scene {
        Window("Photo Club Hub HTML", id: "mainWindow") {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
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

        // load list of photo clubs and museums from root.Level1.json file TODO
//        let level1BackgroundContext = PersistenceController.shared.container.newBackgroundContext()
//        level1BackgroundContext.name = "root.level1.json"
//        level1BackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//        level1BackgroundContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?
//        _ = Level1JsonReader(bgContext: level1BackgroundContext, // read root.Level1.json file
//                             useOnlyFile: false)

        // warning: following clubs rely on Level 1 file to provide their geographic coordinates

        // load test member(s) of Fotogroep Bellus Imago
//        let bellusBackgroundContext = PersistenceController.shared.container.newBackgroundContext()
//        bellusBackgroundContext.name = "Bellus Imago"
//        bellusBackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//        bellusBackgroundContext.automaticallyMergesChangesFromParent = true
//        _ = BellusImagoMembersProvider(bgContext: bellusBackgroundContext)

        // load all current/former members of Fotogroep Waalre
//        let waalreBackgroundContext = PersistenceController.shared.container.newBackgroundContext()
//        waalreBackgroundContext.name = "Fotogroep Waalre"
//        waalreBackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//        waalreBackgroundContext.automaticallyMergesChangesFromParent = true
//        _ = FotogroepWaalreMembersProvider(bgContext: waalreBackgroundContext)

        // load member(s) of Fotogroep De Gender
//        let genderBackgroundContext = PersistenceController.shared.container.newBackgroundContext()
//        genderBackgroundContext.name = "FG de Gender"
//        genderBackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//        genderBackgroundContext.automaticallyMergesChangesFromParent = true
//        _ = FotogroepDeGenderMembersProvider(bgContext: genderBackgroundContext)

        // load all current members of Fotogroep Anders
//        let andersBackgroundContext = PersistenceController.shared.container.newBackgroundContext()
//        andersBackgroundContext.name = "FG Anders"
//        andersBackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//        andersBackgroundContext.automaticallyMergesChangesFromParent = true
//        _ = AndersMembersProvider(bgContext: andersBackgroundContext)

    }
}
