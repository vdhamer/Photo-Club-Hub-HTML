//
//  Photo_Club_Hub_HTMLApp.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI
import Ignite
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for OrganizationType

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

private let isBeingTested = false // these are being loaded to get the data into Core Data, not for testing purposes

extension PhotoClubHubHtmlApp {

    static func loadClubsAndMembers() async {

        let viewContext = persistenceController.container.viewContext // "associated with the main application queue"
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.undoManager = nil // nil by default on iOS
        viewContext.shouldDeleteInaccessibleFaults = true

        // Clear CoreData database for simplicity and to trigger initConstants()
        Model.deleteCoreDataObjects(viewContext: viewContext, deletionScope: .standard)

        await loadLevels0To2()
    }

    /// Runs one complete load pass: Level 0, then Level 1, then every Level 2 club loader concurrently.
    ///
    /// **Why Level 0 is awaited first.** This ordering is required, not stylistic. `Expertise` has a Core Data
    /// uniqueness constraint on `id_`. Level 0 creates expertises with `isSupported=true`, while Level 2's
    /// `findCreateUpdateUndefSupported()` creates them with the default `isSupported=false`. The contexts merge
    /// by property (see `makeBgContext`), so a Level 2 save racing Level 0 can leave the flag wrong.
    ///
    /// Level 1 is awaited too, but only for simplicity: the package allows Level 1 and Level 2 to overlap, so
    /// this call site is stricter than strictly necessary.
    ///
    /// The `withTaskGroup` makes this function return only after every club loader has finished, so a caller
    /// can treat "the load pass is over" as a fact — which is what lets the Fill database menu item and the
    /// website generation that follows it see a complete database.
    ///
    /// Deliberately mirrors `PhotoClubHubApp.loadLevels0To2()` in the iOS app: the two are scheduled to be
    /// replaced by a single package-level entry point (vdhamer/Photo-Club-Hub-Data#12), and keeping them
    /// structurally identical reduces that to a call-site swap in each app.
    nonisolated static func loadLevels0To2() async { // swiftlint:disable:this function_body_length

        let useOnlyInBundleFile = false

        // MARK: - Level 0

        // load list of Expertises and Languages from root.Level0.json file
        await Level0JsonReader.load(
            bgContext: makeBgContext(ctxName: "Level 0 loader"),
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // MARK: - Level 1

        // Load list of organizations from root_.Level1.json file (which Includes additional Level 1 child files).
        let fileName = "root_"
        await Level1JsonReader.load(
            bgContext: makeBgContext(ctxName: "Level 1 loader for \(fileName)"),
            fileName: fileName,
            isBeingTested: isBeingTested,
            useOnlyInBundleFile: useOnlyInBundleFile)

        // MARK: - Level 2

        // Load all clubs with Level 2 files concurrently within one load pass.
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await FotogroepDeGenderMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader fgDeGender"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await FotogroepWaalreMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader fgWaalre"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await FotoclubBellusImagoMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader fcBellusImago"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await FotogroepOirschotMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader fgOirschot"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await TemplateMinMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader TemplateMin"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await TemplateMaxMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader TemplateMax"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await Persoonlijk16MembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader Persoonlijk16"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await FotoclubEricameraMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader fcEricamera"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await FotoclubDenDungenMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader fcDenDungen"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await FotokringStMichielsgestelMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader fkGestel"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await Persoonlijk03MembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader Persoonlijk03"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await FotoclubVeghelMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader fcVeghel"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await FFCShot71MembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader ffcShot71"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
            group.addTask {
                await FEGGemertMembersProvider.load(
                    bgContext: makeBgContext(ctxName: "Level 2 loader fegGemert"),
                    isBeingTested: isBeingTested,
                    useOnlyInBundleFile: useOnlyInBundleFile)
            }
        }
    }

    nonisolated static func makeBgContext(ctxName: String) -> NSManagedObjectContext {

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = ctxName
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?
        return bgContext

    }
}
