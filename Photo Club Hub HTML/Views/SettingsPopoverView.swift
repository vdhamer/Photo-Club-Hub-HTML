//
//  SettingsPopoverView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 16/08/2026.
//

import SwiftUI // this is a SwiftUI view

/// The contents of the toolbar's *Settings…* popover:
/// everything that steers what the next *Generate* and *Preview website* produce.
///
/// Split out of ``ClubListView`` because the rows are mostly boilerplate — a `Toggle` wrapping a localized
/// label plus a `.help` tooltip — and five of them buried the split view they were attached to. Each row is
/// its own computed property, so ``body`` reads as the order the user sees.
///
/// The rows sit in two `Section`s — *Hosting* (how the site is served) and *Content* (what appears on the
/// pages) — in a `Form` styled `.grouped`, i.e. the same containers a macOS Settings pane uses. A `Form` is
/// what makes section headers headers at all: outside a `Form` or a `List`, `Section` renders its header as
/// ordinary text. `doneButton` stays outside the `Form`, or it would become a third, unlabeled section.
///
/// The section fill is the system's and is left alone. It cannot be restyled anyway —
/// `.scrollContentBackground(.hidden)`, a darker `.background` and `.listRowBackground` are all ignored, and
/// the grouped style paints its own page background over them — but the reason not to hand-draw the panels
/// instead is that the fill only looks too faint in an Xcode Preview, which puts these contents on a flat
/// white window. The real popover is Liquid Glass, and against that the stock boxes read fine, so the app
/// gets the system look for free and keeps whatever Apple does to it next (#249).
///
/// This owns no state: every row binds straight into ``PreferencesStructHTML``, which ``ClubListView`` holds.
struct SettingsPopoverView: View {

    @Binding var preferences: PreferencesStructHTML

    /// Bound to the popover's own presentation, so the *Done* button can dismiss it.
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Form {

                Section {
                    hostPicker
                    AllowRemotePreviewToggle(preferences: $preferences)
                    localThumbnailsToggle
                } header: {
                    Text(hostingHeader)
                }

                Section {
                    formerMembersToggle
                    fotobondNumbersToggle
                } header: {
                    Text(contentHeader)
                }

            }
            .formStyle(.grouped)

            doneButton
                .padding([.horizontal, .bottom])

        }
        .frame(minWidth: 380)
    }

    private var hostingHeader: String {
        String(localized: "Hosting",
               table: "PhotoClubHubHTML.SwiftUI",
               comment: "Header of the Settings section with settings about where the generated website is served from")
    }

    private var contentHeader: String {
        String(localized: "Content",
               table: "PhotoClubHubHTML.SwiftUI",
               comment: "Header of the Settings section with toggles about what appears on the generated pages")
    }

    /// Which host the generated links and SEO metadata should point at.
    ///
    /// Left at the default (pop-up menu) picker style rather than `.inline`: inline would put its own *Host*
    /// label straight below the *Hosting* section header, and would spend a row per case in a popover. The
    /// grouped `Form` puts the label at the leading edge and the menu at the trailing edge by itself.
    private var hostPicker: some View {
        Picker(String(localized: "Host",
                      table: "PhotoClubHubHTML.SwiftUI",
                      comment: "Label of picker for targetHost"),
               selection: $preferences.selectedHost) {
            ForEach(TargetHost.allCases, id: \.self) { host in
                Text(host.rawValue).tag(host)
            }
        }
        .help(String(localized: "Selects the host to target when generating a website.",
                     table: "PhotoClubHubHTML.SwiftUI",
                     comment: "Hint about targetHost picker within Settings"))
    }

    private var localThumbnailsToggle: some View {
        Toggle(isOn: $preferences.useLocalThumbnails,
               label: {Text(String(localized: "Copy thumbnails to local folder",
                                   table: "PhotoClubHubHTML.SwiftUI",
                                   comment: "Toggle to enable copying of thumbnails to a local folder"))
                }
        )
        .help(String(localized: "Tells app to make a local copy of remote thumbnails to reduce hot-linking.",
                     table: "PhotoClubHubHTML.SwiftUI",
                     comment: "Usage hint for `useLocalThumbnails` setting"))
    }

    private var formerMembersToggle: some View {
        Toggle(isOn: $preferences.showFormerMembers,
               label: {Text(String(localized: "Include recent former members",
                                   table: "PhotoClubHubHTML.SwiftUI",
                                   comment: "Toggle to enable displaying former club members in extra table"))
                }
        )
        .help(String(localized: "Tells app to display former members in extra table.",
                     table: "PhotoClubHubHTML.SwiftUI",
                     comment: "Usage hint for `showFormerMembers` setting"))
    }

    private var fotobondNumbersToggle: some View {
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
    }

    private var doneButton: some View {
        HStack {
            Spacer()
            Button(String(localized: "Done",
                          table: "PhotoClubHubHTML.SwiftUI",
                          comment: "Button to close the settings popover")) {
                isPresented = false
            }
        }
    }

}

// Believe it or not, this preview actually works

#Preview {
    @Previewable @State var preferences = PreferencesStructHTML.defaultValue
    @Previewable @State var isPresented = true
    SettingsPopoverView(preferences: $preferences, isPresented: $isPresented)
}
