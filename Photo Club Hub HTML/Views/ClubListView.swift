//
//  ContentView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI // this is a SwiftUI view
import CoreData // for FetchRequest?
import Photo_Club_Hub_Data // for Organization

struct ClubListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var preferences: PreferencesStructHTML
    @State private var localPreferences = PreferencesStructHTML.defaultValue // parameters for various Toggles()

    // MARK: - @FetchRequests to get list of Clubs

    static let clubOnlyPredicate = NSPredicate(format: "organizationType_.organizationTypeName_= %@",
                                               argumentArray: [OrganizationTypeEnum.club.rawValue])
    static let allPredicate = NSPredicate(format: "TRUEPREDICATE")
    static let nonePredicate = NSPredicate(format: "FALSEPREDICATE") // not currently used

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

                    Button(String(localized: "Entire website",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "App button that generates all levels of website at once")) {
                        print("Generating Level 0, Level 1 and Level 2")
                        generateAllLevels(preferences: preferences)
                    }

                    Divider()

                    Button(String(localized: "L0: expertises",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "App button that generates HTML page listing all expertises")) {
                        print("Generating Level 0 expertises")
                        generateLevel0(preferences: preferences)
                    }

                    Divider()

                    Button(String(localized: "L1: clubs",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "App button that generates HTML page listing all clubs")) {
                        print("Generating Level 1 clubs")
                        generateLevel1(preferences: preferences)
                    }

                    Button(String(localized: "L1: museums",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "App button that generates HTML page listing all museums")) {
                        print("Generating Level 1 museums")
                        generateLevel1(preferences: preferences)
                    }

                    Divider()

                    Button(String(localized: "L2: club members",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "App button that generates HTML page listing all club members")) {
                        print("Generating Level 2 club members")
                        generateLevel2(preferences: preferences)
                    }

                } label: {
                    Text(String(localized: "Build HTML",
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
