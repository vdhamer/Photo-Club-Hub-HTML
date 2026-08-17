//
//  WebsiteGeneration.swift
//  Photo Club Hub HTML
//
//  Created by Claude Code under guidance of Peter van den Hamer on 16/08/2026.
//

import SwiftUI // for View

/// The feedback half of *Actions ▸ Generate*: what a run produced, and the alert that reports it (#246).
///
/// Kept out of ``ClubListView`` for the same reason ``PreviewWebsiteButton`` is (#249) — the command that
/// raises this alert lives in a `Menu` that disappears the moment it is used, so the alert has to be hosted
/// by a view that lives as long as the window.

/// What a *Generate* run produced, as of the moment `publish()` returned.
///
/// Not `Result`: the failure carries an already-localized message rather than the `Error`, because that is all
/// the alert shows and it keeps the type free of the `any Error` that would otherwise cross into `@State`.
enum WebsiteGenerationOutcome: Equatable {

    /// The site is on disk. `pageCount` includes the landing page.
    case succeeded(pageCount: Int)

    /// Publishing threw. `reason` is `localizedDescription`, shown verbatim.
    case failed(reason: String)

}

/// The completion alert, hosted by a view that outlives the Actions menu.
private struct WebsiteGenerationSupport: ViewModifier {

    /// Non-nil while the alert is up. Owned by the hosting view, which sets it when a generate finishes.
    @Binding var outcome: WebsiteGenerationOutcome?

    /// Needed only by the *Preview website* button, which honours `allowRemotePreview` like the menu item does.
    let preferences: PreferencesStructHTML

    /// Where a failure to start the preview server goes: the alert that
    /// ``SwiftUI/View/websitePreviewSupport(error:allowRemotePreview:)`` already hosts.
    /// Raising it from here is safe because this alert has dismissed by the time the button's action runs.
    @Binding var previewError: String?

    /// One alert with two faces. A single `.alert` rather than two mutually exclusive ones, so that success and
    /// failure cannot both be presented at once — which is what makes the "generate finished" state a single
    /// optional, and dismissal a single `nil`.
    private var title: String {
        if case .failed = outcome {
            String(localized: "Cannot generate the website",
                   table: "PhotoClubHubHTML.SwiftUI",
                   comment: "Title of the alert shown when generating the website failed")
        } else {
            // Also the title while `outcome` is nil and the alert is on its way out: SwiftUI reads the title
            // during dismissal, and the success wording is the harmless one to be caught holding.
            String(localized: "Website generated",
                   table: "PhotoClubHubHTML.SwiftUI",
                   comment: "Title of the alert shown when the website has been generated")
        }
    }

    func body(content: Content) -> some View {
        content
            .alert(title,
                   isPresented: Binding(get: { outcome != nil },
                                        set: { if !$0 { outcome = nil } }),
                   presenting: outcome) { outcome in
                if case .succeeded = outcome {
                    Button(String(localized: "Show website preview",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "App button that serves the generated website and opens a browser")) {
                        Task {
                            do {
                                try await WebsitePreview.open(preferences: preferences)
                            } catch {
                                previewError = error.localizedDescription
                            }
                        }
                    }

                    Button(String(localized: "Show as files (in Finder)",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "Alert button that reveals the generated website in the Finder")) {
                        SiteOutput.revealInFinder()
                    }
                }

                // No Show in Finder on a failure: publish() clears Build/ before it writes, so what is left
                // after a throw is a half-written tree that revealing would only make look intact.
                Button(String(localized: "Close",
                              table: "PhotoClubHubHTML.SwiftUI",
                              comment: "Button that dismisses an alert when website preview failed"),
                       role: .cancel) {
                    self.outcome = nil
                }
            } message: { outcome in
                switch outcome {
                case .succeeded(let pageCount):
                        Text(String(localized: "\(pageCount) pages were generated.",
                                    table: "PhotoClubHubHTML.SwiftUI",
                                    comment: "Alert message stating how many pages were generated"))
                case .failed(let reason):
                    Text(verbatim: reason)
                }
            }
    }

}

extension View {

    /// Hosts the alert that reports the result of *Actions ▸ Generate*. Apply to a view that lives as long as
    /// the window, not to the menu item — and alongside
    /// ``SwiftUI/View/websitePreviewSupport(error:allowRemotePreview:)``, whose alert this one's
    /// *Preview website* button reports into.
    func websiteGenerationSupport(outcome: Binding<WebsiteGenerationOutcome?>,
                                  preferences: PreferencesStructHTML,
                                  previewError: Binding<String?>) -> some View {
        modifier(WebsiteGenerationSupport(outcome: outcome, preferences: preferences, previewError: previewError))
    }

}

// Both faces of the alert, which are otherwise awkward to reach: the success one needs a full generate, and
// the failure one needs publish() to throw. Unreachable via ``ClubListView``'s own preview because that pulls
// in @FetchRequest views, which crash in Previews in this target (see the note in MembershipView.swift).
//
// The buttons are live: Show in Finder opens the real container, and Preview website starts the real server.
// The strings on the buttons below are deliberately verbatim — preview scaffolding is not localized.

// These 2 previews work, but are not particularly useful

#Preview("Website generated alert") {
    @Previewable @State var outcome: WebsiteGenerationOutcome? = .succeeded(pageCount: 312)
    @Previewable @State var previewError: String?

    Button {
        outcome = .succeeded(pageCount: 312)
    } label: {
        Text(verbatim: "Raise the success alert again")
    }
    .frame(width: 320, height: 120)
    .websiteGenerationSupport(outcome: $outcome,
                              preferences: PreferencesStructHTML.defaultValue,
                              previewError: $previewError)
}

#Preview("Website generation failure alert") {
    @Previewable @State var outcome: WebsiteGenerationOutcome? =
        .failed(reason: "The file “Assets” couldn’t be opened because you don’t have permission to view it.")
    @Previewable @State var previewError: String?

    Button {
        outcome = .failed(reason: "The file “Assets” couldn’t be opened because you don’t have permission " +
                                  "to view it.")
    } label: {
        Text(verbatim: "Raise the failure alert again")
    }
    .frame(width: 320, height: 120)
    .websiteGenerationSupport(outcome: $outcome,
                              preferences: PreferencesStructHTML.defaultValue,
                              previewError: $previewError)
}
