//
//  ClubListView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI // this is a SwiftUI view
import CoreData // for FetchRequest?
import Photo_Club_Hub_Data // for Organization, deleteAllCoreDataObjects

/// The app's root content view: a `NavigationSplitView` listing photo clubs alongside a detail pane,
/// plus the toolbar that drives the static-site generation workflow.
///
/// Layout:
/// - **Sidebar**: `ClubListSidebarView` shows the list of clubs and tracks the selection in `selectedClubIds`.
/// - **Detail**: `MembershipView` for the selected club, or a placeholder prompt when nothing is selected.
/// - **Footer**: `RecordsFooterView` shows database/translation statistics below a divider.
///
/// The toolbar exposes two controls:
/// - **Settings…**: a popover binding the shared ``PreferencesStructHTML`` (target host, local thumbnails,
///   former members, Fotobond numbers).
/// - **Actions**: a menu to Generate the website, Clear/Fill the CoreData database, and reverse-geocode
///   localized Town & Country.
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
                    Text(String(localized: "Please select a club in the sidebar.",
                                table: "PhotoClubHubHTML.SwiftUI", // in System language as this is SwiftUI UI code
                                comment: "Message displayed when no club is selected"))
                        .font(.title2)
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 600)
            .navigationSplitViewStyle(.balanced) // don't see a difference between .balanced and .prominentDetail

            Divider()
            RecordsFooterView()
        }

        .onAppear {
            NSWindow.allowsAutomaticWindowTabbing = false // disable tab bar (HackingWithSwift macOS StormViewer)
            // Ignite's publish() copies Assets/ from NSHomeDirectory() to Build/; create the directory up front
            let assetsURL = URL(filePath: NSHomeDirectory()).appending(path: "Assets")
            let assetsImagesURL = assetsURL.appending(path: "images")
            try? FileManager.default.createDirectory(at: assetsImagesURL, withIntermediateDirectories: true)
            copyBundleResource(named: "AppIcon", extension: "png", to: assetsImagesURL)
            copyBundleResource(named: "favicon", extension: "png", to: assetsURL)
        }
        .frame(minWidth: 640, minHeight: 390)
        .padding()
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
                    VStack(alignment: .leading, spacing: 12) {

                        Picker(String(localized: "Host",
                                      table: "PhotoClubHubHTML.SwiftUI",
                                      comment: "Label of picker for targetHost"),
                               selection: $preferences.selectedHost) {
                            ForEach(TargetHost.allCases, id: \.self) { host in
                                Text(host.rawValue).tag(host)
                            }
                        }
                        .pickerStyle(.inline)
                        .help(String(localized: "Selects the host to target when generating a website.",
                                     table: "PhotoClubHubHTML.SwiftUI",
                                     comment: "Hint about targetHost picker within Settings"))

                        Toggle(isOn: $preferences.useLocalThumbnails,
                               label: {Text(String(localized: "Copy thumbnails to local folder",
                                                   table: "PhotoClubHubHTML.SwiftUI",
                                                   comment: "Toggle to enable copying of thumbnails to a local folder"))
                                }
                        )
                        .help(String(localized: """
                                                Tells app to make a local copy of remote thumbnails \
                                                to reduce hot-linking.
                                                """,
                                     table: "PhotoClubHubHTML.SwiftUI",
                                     comment: "Usage hint for `useLocalThumbnails` setting"))

                        Toggle(isOn: $preferences.showFormerMembers,
                               label: {Text(String(localized: "Include recent former members",
                                                   table: "PhotoClubHubHTML.SwiftUI",
                                                   comment: """
                                                            Toggle to enable displaying former club members \
                                                            in extra table
                                                            """))
                                }
                        )
                        .help(String(localized: """
                                                Tells app to display former members in extra table.
                                                """,
                                     table: "PhotoClubHubHTML.SwiftUI",
                                     comment: "Usage hint for `showFormerMembers` setting"))

                        Toggle(isOn: $preferences.showFotobondMemberNumber,
                               label: {Text(String(localized: "Show Fotobond (NL) membership numbers",
                                                   table: "PhotoClubHubHTML.SwiftUI",
                                                   comment: """
                                                            Toggle to enable displaying of Fotobond (NL) \
                                                            membership numbers of photographers
                                                            """))
                                }
                        )
                        .help(String(localized: """
                                                Tells app to display Fotobond number of members when cursor \
                                                hovers over membership years data.
                                                """,
                                     table: "PhotoClubHubHTML.SwiftUI",
                                     comment: "Usage hint for `showFotobondMemberNumber` setting"))

                        HStack {
                            Spacer()
                            Button(String(localized: "Done",
                                          table: "PhotoClubHubHTML.SwiftUI",
                                          comment: "Button to close the settings popover")) {
                                showSettingsPopover = false
                            }
                        }

                    }
                    .padding()
                    .frame(minWidth: 320)
                }

                Menu {

                    Button(String(localized: "Generate",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "App button that generates all website pages")) {
                        print("Action: Generating website")
                        generateAllLevels(preferences: preferences)
                    }

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
                        PhotoClubHubHtmlApp.loadClubsAndMembers()
                    }

                    // Manually trigger reverse-geocoding of localized Town & Country.
                    Button(String(localized: "Translate Country & Town",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "Button that reverse-geocodes Town/Country for all Organizations")) {
                        print("Action: Translating Town & Country")
                        Task { await OrganizationGeocoder().geocodeChangedAddresses() }
                    }

                } label: {
                    Text(String(localized: "Actions",
                                table: "PhotoClubHubHTML.SwiftUI",
                                comment: "Submenu for generating Level 0 ... Level 2 HTML pages"))
                }

           }
        }
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
