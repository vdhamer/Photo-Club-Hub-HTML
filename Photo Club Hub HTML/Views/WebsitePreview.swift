//
//  WebsitePreview.swift
//  Photo Club Hub HTML
//
//  Created by Claude Code under guidance of Peter van den Hamer on 16/08/2026.
//

import SwiftUI // this is a SwiftUI view
import AppKit // for NSWorkspace

/// The *Preview website* command, kept out of ``ClubListView`` so that view stays readable (#249).
///
/// This is three fragments rather than one subview, because SwiftUI decides where each has to live.
/// The button belongs in an Actions `Menu` and the toggle in the Settings popover, and both of those vanish
/// from the view hierarchy the moment they are used — so neither can host the failure alert, and neither
/// can host the `onChange` that moves a running server between interfaces. Those two attach to the split
/// view itself, via ``SwiftUI/View/websitePreviewSupport(error:allowRemotePreview:)``, and stay alive as
/// long as the window does.
///
/// None of the three names ``ClubListView``: each takes what it needs as a parameter, so the same command
/// can be placed by whatever view ends up owning the menu.

/// The *Preview website* item for the Actions menu.
///
/// A `file://` link cannot replace this: the generated pages link root-relative (`/en/clubs/`), which
/// needs a server to resolve against a document root and to turn a directory into its `index.html`
/// (#247).
struct PreviewWebsiteButton: View {

    let preferences: PreferencesStructHTML

    /// Set when the server could not be started, which raises the alert hosted by
    /// ``SwiftUI/View/websitePreviewSupport(error:allowRemotePreview:)``.
    @Binding var error: String?

    var body: some View {
        Button(String(localized: "Preview website",
                      table: "PhotoClubHubHTML.SwiftUI",
                      comment: "App button that serves the generated website and opens a browser")) {
            print("Action: Previewing website")
            previewWebsite()
        }
    }

    /// Starts the preview server if it isn't already running, then opens a browser on the port it bound.
    ///
    /// The bound port can differ from the default when something else on this Mac is already listening there;
    /// the browser follows the server rather than the setting, so the fallback is not a broken link.
    /// Failures land in the alert instead of only on the console.
    private func previewWebsite() {
        Task {
            do {
                let allowRemoteAccess = preferences.allowRemotePreview
                let port = try await PreviewServer.shared.start(preferredPort: SiteOutput.defaultPreviewPort,
                                                               directory: SiteOutput.buildDirectory,
                                                               allowRemoteAccess: allowRemoteAccess)
                NSWorkspace.shared.open(SiteOutput.previewURL(port: port, allowRemoteAccess: allowRemoteAccess))
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

}

/// The *Allow previewing on other devices too* row of the Settings popover.
///
/// It lives in this file rather than with the other settings rows because what it means is a property of the
/// preview server: off by default, and ``PreviewServer`` documents why binding every interface has to be
/// opt-in.
struct AllowRemotePreviewToggle: View {

    @Binding var preferences: PreferencesStructHTML

    var body: some View {
        Toggle(isOn: $preferences.allowRemotePreview,
               label: {Text(String(localized: "Allow previewing on other devices too",
                                   table: "PhotoClubHubHTML.SwiftUI",
                                   comment: """
                                            Toggle to let the preview website be opened from \
                                            phones and other computers on the same network
                                            """))
                }
        )
        .help(String(localized: "Enables a phone, tablet or other computer on the same LAN to open the preview.",
                     table: "PhotoClubHubHTML.SwiftUI",
                     comment: "Usage hint for `allowRemotePreview` setting"))
    }

}

/// The two parts of the preview command that need a host which outlives the menu and the popover:
/// the failure alert, and applying a change of ``PreferencesStructHTML/allowRemotePreview``.
private struct WebsitePreviewSupport: ViewModifier {

    /// Non-nil while the failure alert is up. Owned by the hosting view because ``PreviewWebsiteButton``
    /// writes it too.
    @Binding var previewError: String?

    let allowRemotePreview: Bool

    func body(content: Content) -> some View {
        content
            .alert(String(localized: "Cannot preview the website",
                          table: "PhotoClubHubHTML.SwiftUI",
                          comment: "Title of the alert shown when the preview server could not be started"),
                   isPresented: Binding(get: { previewError != nil },
                                        set: { if !$0 { previewError = nil } }),
                   presenting: previewError) { _ in
                Button(String(localized: "OK",
                              table: "PhotoClubHubHTML.SwiftUI",
                              comment: "Button that dismisses an alert when website preview failed")) {
                    previewError = nil
                }
            } message: { reason in
                Text(verbatim: reason)
            }
            // Move a running preview server the moment the setting changes, rather than at the next preview:
            // the natural way to check the toggle is to reload the page already open on the phone.
            .onChange(of: allowRemotePreview) { _, allowRemoteAccess in
                Task {
                    do {
                        try await PreviewServer.shared.applyRemoteAccess(allowRemoteAccess,
                                                                         directory: SiteOutput.buildDirectory)
                    } catch {
                        previewError = error.localizedDescription
                    }
                }
            }
    }

}

extension View {

    /// Hosts the preview command's failure alert, and applies a change of `allowRemotePreview` to a running
    /// server. Apply to a view that lives as long as the window, not to the menu item or the popover.
    ///
    /// Apply it *once* per process: it drives the ``PreviewServer/shared`` singleton, so a second host would
    /// mean two `onChange` handlers reconfiguring one server, and a failure raising only one of two alerts.
    func websitePreviewSupport(error: Binding<String?>, allowRemotePreview: Bool) -> some View {
        modifier(WebsitePreviewSupport(previewError: error, allowRemotePreview: allowRemotePreview))
    }

}

// Shows the failure alert, which in the app only appears when the server cannot bind a port — awkward to
// provoke by hand, and unreachable via ``ClubListView``'s own preview because that pulls in @FetchRequest
// views, which crash in Previews in this target (see the note in MembershipView.swift).
//
// Nothing here touches ``PreviewServer``: `allowRemotePreview` is a constant, so the `onChange` never fires.
// The strings are deliberately verbatim — preview scaffolding does not belong in the string catalog.

#Preview("Website preview failure alert") {
    @Previewable @State var error: String? = "The operation couldn’t be completed. Address already in use."

    Button {
        error = "The operation couldn’t be completed. Address already in use."
    } label: {
        Text(verbatim: "Raise the alert again")
    }
    .frame(width: 320, height: 120)
    .websitePreviewSupport(error: $error, allowRemotePreview: false)
}
