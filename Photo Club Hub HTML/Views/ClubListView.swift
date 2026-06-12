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
    static let nonePredicate = NSPredicate(format: "FALSEPREDICATE")

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
            // some Ignite forks may requires an Assets directory at NSHomeDirectory() when running as a sandboxed app
            try? FileManager.default.createDirectory( at: URL(filePath: NSHomeDirectory()).appending(path: "Assets"),
                                                      withIntermediateDirectories: true )
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
                    } .disabled(true)

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

    private func generateLevel0(preferences: PreferencesStructHTML) { // index with all expertises

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level0.publishing"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        bgContext.performAndWait { // generate website
            let level0Site = Level0Site(moc: bgContext, preferences: preferences) // load data
            Task {
                do {
                    try await level0Site.publish() // generate HTML
                } catch {
                    ifDebugFatalError("Publishing of results of Level0Site() failed. Error: \(error)")
                    print(error.localizedDescription)
                }
            }
        }
    }

    private func generateSingleExpertiseLanguagePage(expertiseID: String,
                                                     language: String,
                                                     preferences: PreferencesStructHTML) {
        print("Generating expertise page for expertise <\(expertiseID)> in language <\(language)>")
        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "ExpertiseLanguagePage.publishing"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true

        bgContext.performAndWait {
            let level0SingleExpertiseSite = ExpertisePageSite(expertiseID: expertiseID,
                                                              language: language,
                                                              moc: bgContext,
                                                              preferences: preferences) // for selectedHost
            Task {
                do {
                    try await level0SingleExpertiseSite.publish(buildDirectoryPath:
                        "Build/" + ExpertisesPage.relativePath(languageID: language, expertiseID: expertiseID))
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    private func generateLevel1(preferences: PreferencesStructHTML) { // index with all clubs

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level1.publishing"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true // to push ObjectTypes to bgContext?

        bgContext.performAndWait { // generate website
            let level1Site = Level1Site(moc: bgContext, preferences: preferences) // load data
            Task {
                do {
                    try await level1Site.publish() // generate HTML
                } catch {
                    ifDebugFatalError("Publishing of results of Level1Site() failed. Error: \(error)")
                    print(error.localizedDescription)
                }
            }
        }
    }

    /// Generates one Level 2 HTML page for each (club × language) combination.
    ///
    /// Delegates to `Level2Site`, which fetches all clubs and all languages from CoreData and creates
    /// one `Members` page per combination — but only for languages that have at least one
    /// `LocalizedExpertise` translation (keeping Level 2 output consistent with Level 0 expertise pages).
    /// All CoreData reads happen inside `performAndWait` on a dedicated background context;
    /// Ignite's `publish()` is then called asynchronously via a `Task`.
    private func generateLevel2(preferences: PreferencesStructHTML) { // all clubs × all languages

        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.name = "Level2.publishing"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        bgContext.automaticallyMergesChangesFromParent = true

        bgContext.performAndWait {
            let level2Site = Level2Site(moc: bgContext, preferences: preferences)
            Task {
                do {
                    try await level2Site.publish()
                } catch {
                    ifDebugFatalError("Publishing of results of Level2Site() failed. Error: \(error)")
                    print(error.localizedDescription)
                }
            }
        }
    }

}

#Preview {
    @Previewable @State var preferences = PreferencesStructHTML.defaultValue
    ClubListView(preferences: $preferences)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
