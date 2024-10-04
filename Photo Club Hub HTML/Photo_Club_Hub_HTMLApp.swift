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
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .undoRedo) { }
//            CommandGroup(replacing: .pasteboard) { }
            CommandGroup(replacing: .help) { }
            CommandGroup(replacing: .systemServices) { }
        }
    }
}
