//
//  Photo_Club_Hub_HTMLApp.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI
import Ignite
import CoreData // for NSMergePolicy
import Photo_Club_Hub_Data // for OrganizationType, Model and LevelLoader

@main
struct PhotoClubHubHtmlApp: App {
    @StateObject var model = PreferencesViewModelHTML()
    @Environment(\.openWindow) private var openWindow: OpenWindowAction

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
            ClubListView(preferences: $model.preferences)
                .environment(\.managedObjectContext, Self.persistenceController.container.viewContext)
                // Quit on main window close: macOS keeps a windowless app running by default, and an
                // open auxiliary window (e.g. About) would otherwise keep it alive after the main
                // window is gone.
                .onDisappear {
                    NSApp.terminate(nil)
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button {
                    openWindow(id: "about")
                } label: {
                    Text("About Photo Club Hub HTML",
                         tableName: "PhotoClubHubHTML.SwiftUI",
                         comment: "Menu item that opens the About window")
                }
            }
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .undoRedo) { }
            CommandGroup(replacing: .help) { }
            CommandGroup(replacing: .systemServices) { }
            CommandGroup(replacing: .pasteboard) { } // Suppresses Apple Intelligence's Writing Tools in the menu
        }

        Window(String(localized: "About Photo Club Hub HTML",
                      table: "PhotoClubHubHTML.SwiftUI",
                      comment: "Menu item that opens the About window"),
               id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}

extension PhotoClubHubHtmlApp {

    /// Wipes the database and rebuilds it from the JSON files, returning only once the last club has loaded.
    ///
    /// The ordering *within* a pass — Level 0 awaited to completion before any Level 2 loader starts, because of
    /// the uniqueness constraint on `Expertise.id_` — belongs to `LevelLoader` in the Photo Club Hub Data
    /// package, along with the merge policy it depends on and the list of clubs (Data#12). What stays here is
    /// this app's own decision to start every pass from an empty database.
    static func loadClubsAndMembers() async {

        let viewContext = persistenceController.container.viewContext // "associated with the main application queue"
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.undoManager = nil // nil by default on iOS
        viewContext.shouldDeleteInaccessibleFaults = true

        // Clear CoreData database for simplicity and to trigger initConstants()
        Model.deleteCoreDataObjects(viewContext: viewContext, deletionScope: .standard)

        await LevelLoader.loadAllLevels()
    }
}
