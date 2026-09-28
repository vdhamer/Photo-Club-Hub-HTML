//
//  ClubListView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI // this is a SwiftUI view
import Photo_Club_Hub_Data // for Organization, deleteAllCoreDataObjects

/// The app's root content view: a `NavigationSplitView` listing photo clubs alongside a detail pane,
/// plus the toolbar that drives the static-site generation workflow.
///
/// Layout:
/// - **Sidebar**: `ClubListSidebarView` shows the list of clubs and tracks the selection in `selectedClubIds`.
/// - **Detail**: `MembershipView` for the selected club, or a placeholder prompt when nothing is selected.
/// - **Footer**: `RecordsFooterView` shows stats below a divider, including progress of the town/country translation.
///
/// The toolbar exposes two controls:
/// - **Settings…**: a popover, ``SettingsPopoverView``, binding the shared ``PreferencesStructHTML``.
/// - **Actions**: a menu to Generate the website, and preview it in a browser (``PreviewWebsiteButton``),
///   Clear/Fill the CoreData database, and reverse-geocode localized Town & Country.
///
/// Only the parts SwiftUI requires to sit here are here: the website generation lives in
/// `ClubListView+HTMLGeneration.swift`, and the preview command in `WebsitePreview.swift`.
///
/// On appear it disables window tabbing and pre-creates the `NSHomeDirectory()/Assets` directory (with a
/// bundled app icon and favicon) so Ignite's `publish()` can copy assets into `Build/`.
struct ClubListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var preferences: PreferencesStructHTML
    @State private var localPreferences = PreferencesStructHTML.defaultValue // parameters for various Toggles()

    // MARK: - @FetchRequests to get list of Clubs

    static let clubOnlyPredicate = NSPredicate(format: "organizationType_.organizationTypeName_= %@",
                                               argumentArray: [OrganizationTypeEnum.club.rawValue])

    // computed (not stored) so each access returns a fresh NSPredicate: NSPredicate isn't Sendable,
    // so a `static let` would be rejected under Swift 6 strict concurrency checking
    static var allPredicate: NSPredicate { NSPredicate(format: "TRUEPREDICATE") }
    static var nonePredicate: NSPredicate { NSPredicate(format: "FALSEPREDICATE") } // not currently used

    // MARK: - @FetchRequests to get lists and get counts

    // MARK: - Body of ClubListView

    @State private var selectedClubIds: Set<OrganizationID> = []
    @State private var showSettingsPopover: Bool = false
    @State private var isLoadingDatabase: Bool = false // drives the "Fill database" command's spinner
    @State private var isGeneratingWebsite: Bool = false // drives the "Generate" command's spinner
    @State private var generationOutcome: WebsiteGenerationOutcomeEnum? // non-nil while the "Generate" alert is up
    @State private var previewError: String? // non-nil while the "Preview website" failure alert is up
    @State private var canPreviewWebsite = false // Build/ holds a localhost build: SiteOutput.isGeneratedForLocalhost()

    @State private var runningSweepsCountTemp = 0 // geocoding sweeps in progress; Int because two can overlap (#271)
    private var isTranslating: Bool { runningSweepsCountTemp > 0 }

    var body: some View {
        VStack(alignment: .leading) {
            NavigationSplitView {
                ClubListSidebarView(preferences: $preferences, selectedClubIds: $selectedClubIds)
            }

            detail: {
                if let clubId = selectedClubIds.first,
                   let club = try? Organization.find(context: viewContext, organizationID: clubId) {
                    MembershipView(club: club, preferences: $preferences)
                } else {
                    Text(String(localized: "Please select a club in the sidebar (on the left).",
                                table: "PhotoClubHubHTML.SwiftUI", // in System language as this is SwiftUI UI code
                                comment: "Message displayed when no club is selected"))
                        .font(.title2)
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 600)
            .navigationSplitViewStyle(.balanced) // don't see a difference between .balanced and .prominentDetail

            Divider()
            RecordsFooterView(isTranslating: isTranslating)
                .padding([.horizontal, .bottom])
        }
        .task {
            // Auto-load once at launch (skipped in Previews); reuses the Fill database spinner.
            guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
            isLoadingDatabase = true
            await PhotoClubHubHtmlApp.loadClubsAndMembers()
            isLoadingDatabase = false
        }
        .overlay {
            // Only one of these can be up: Generate is started by hand, and the launch-time fill has finished
            // long before a menu can be opened. The order is just a tie-break, not a policy.
            if isLoadingDatabase {
                spinner(String(localized: "Loading database…",
                               table: "PhotoClubHubHTML.SwiftUI",
                               comment: "Spinner label shown while the database is being filled"))
            } else if isGeneratingWebsite {
                spinner(String(localized: "Generating website…",
                               table: "PhotoClubHubHTML.SwiftUI",
                               comment: "Spinner label shown while the website is being generated"))
            }
        }
        .websiteGenerationSupport(outcome: $generationOutcome, // custom view modifier
                                  preferences: preferences,
                                  canPreviewWebsite: canPreviewWebsite,
                                  previewError: $previewError)
        .websitePreviewSupport(error: $previewError, allowRemotePreview: preferences.allowRemotePreview)
        .onAppear {
            NSWindow.allowsAutomaticWindowTabbing = false // disable tab bar (HackingWithSwift macOS StormViewer)
            canPreviewWebsite = SiteOutput.isGeneratedForLocalhost() // the build survives a relaunch
            // Ignite's publish() copies Assets/ from NSHomeDirectory() to Build/; create the directory up front
            let assetsURL = URL(filePath: NSHomeDirectory()).appending(path: "Assets")
            let assetsImagesURL = assetsURL.appending(path: "images")
            try? FileManager.default.createDirectory(at: assetsImagesURL, withIntermediateDirectories: true)
            copyBundleResource(named: "AppIcon", extension: "png", to: assetsImagesURL)
            copyBundleResource(named: "favicon", extension: "png", to: assetsURL)
        }
        // No .padding() here: the split view must touch the toolbar. Its lists reserve room under the toolbar for
        // the scroll-edge blur, so any inset above them shows up as a gap plus a blurred band (macOS 27).
        .frame(minWidth: 640, minHeight: 390)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {

                Button {
                    showSettingsPopover.toggle()
                } label: {
                    Text(String(localized: "Settings…",
                                 table: "PhotoClubHubHTML.SwiftUI",
                                 comment: "Submenu for various settings"))
                }
                .popover(isPresented: $showSettingsPopover, arrowEdge: .top) {
                    SettingsPopoverView(preferences: $preferences, isPresented: $showSettingsPopover)
                }

                Menu {

                    Button(String(localized: "Generate",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "App button that generates all website pages")) {
                        print("Action: Generating website")
                        generateWebsite()
                    }

                    PreviewWebsiteButton(preferences: preferences,
                                         canPreviewWebsite: canPreviewWebsite, // true if dealing with localhost
                                         error: $previewError)

                    Divider()

                    Button(String(localized: "Clear database",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "App button that clears internal database content")) {
                        print("Action: Clear database")
                        Model.deleteCoreDataObjects(viewContext: viewContext, deletionScope: .all)
                    }

                    Button(String(localized: "Fill database",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "App button that loads JSON data into the internal database")) {
                        print("Action: Fill database")
                        Task {
                            isLoadingDatabase = true
                            await PhotoClubHubHtmlApp.loadClubsAndMembers()
                            isLoadingDatabase = false
                        }
                    }

                    // Manually trigger reverse-geocoding of localized Town & Country.
                    Button(String(localized: "Translate locations",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "Button that reverse-geocodes Town/Country for all Organizations")) {
                        print("Action: Translating Town & Country")
                        Task { await translateTownsAndCountries() }
                    }

                } label: {
                    Text(String(localized: "Actions",
                                table: "PhotoClubHubHTML.SwiftUI",
                                comment: "Submenu for generating Level 0 ... Level 2 HTML pages"))
                }

           }
        }
    }

    /// The overlay both long-running commands put up, so they cannot drift apart in style.
    private func spinner(_ label: String) -> some View {
        ProgressView(label)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    /// Runs *Actions → Generate*: spinner up, publish, report, then the slow geocoding tail unattended.
    ///
    /// The alert is raised when `publishAllLevels` returns — the moment the site is on disk — and not when this
    /// task ends, because reverse-geocoding runs on for about five minutes after that (#246).
    ///
    /// `@MainActor` is what lets the `Task` write its `@State`s. It does not put the generating on the main
    /// thread: `publishAllLevels` is `nonisolated`, so the `performAndWait` work inside it stays off the main
    /// thread and the spinner keeps spinning.
    @MainActor
    private func generateWebsite() {
        Task {
            isGeneratingWebsite = true // before the first generateLevelN, which blocks its thread once started
            canPreviewWebsite = false // publish() clears Build/ before rewriting it
            let outcome: WebsiteGenerationOutcomeEnum
            do {
                outcome = try await publishAllLevels(preferences: preferences)
            } catch {
                outcome = .failed(reason: error.localizedDescription)
            }
            isGeneratingWebsite = false // spinner down first: the alert should not appear on top of it
            generationOutcome = outcome
            // The build is final here, success or failure. Geocoding below writes only to Core Data.
            canPreviewWebsite = SiteOutput.isGeneratedForLocalhost()

            await translateTownsAndCountries() // may have nothing to do, or may take minutes
        }
    }

    /// Reverse-geocodes the organizations whose town and country are not yet translated, and keeps
    /// ``RecordsFooterView`` informed about whether that is still going on.
    ///
    /// Used after *Generate* and by *Translate locations*. It can be slow (about 10–20 on an empty store)
    /// because the geocoding server is throttled, so after a Generate it runs once the
    /// alert is up rather than before publishing. Its `LocalizedAddress` rows become the localized Country and
    /// Town columns on the next Generate. CoreData acts as the cache that keeps the server from being asked again.
    ///
    /// The database cannot tell whether a sweep is running: the geocoder's work list lives in memory. Hence the
    /// count kept here, which the footer shows as a ⏳ in front of "257 of 294 locations translated" (#271). A count
    /// rather than a Bool, because the two callers can overlap.
    /// Once geocoding goes through the Data package's queue (HTML#258), its status can replace this count.
    private func translateTownsAndCountries() async {
        runningSweepsCountTemp += 1
        await OrganizationGeocoder().geocodeChangedAddresses()
        runningSweepsCountTemp -= 1
    }

    private func copyBundleResource(named name: String, extension ext: String, to directory: URL) {
        guard let source = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        let destination = directory.appending(path: "\(name).\(ext)")
        guard !FileManager.default.fileExists(atPath: destination.path()) else { return }
        try? FileManager.default.copyItem(at: source, to: destination)
    }

}

#Preview {
    @Previewable @State var preferences = PreferencesStructHTML.defaultValue
    ClubListView(preferences: $preferences)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
