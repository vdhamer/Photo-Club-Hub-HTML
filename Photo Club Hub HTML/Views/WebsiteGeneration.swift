//
//  WebsiteGeneration.swift
//  Photo Club Hub HTML
//
//  Created by Claude Code under guidance of Peter van den Hamer on 16/08/2026.
//

import SwiftUI // for View

/// The feedback half of *Actions → Generate*: what a run produced, and the alert that reports it (#246).
///
/// Kept out of ``ClubListView`` for the same reason ``PreviewWebsiteButton`` is (#249) — the command that
/// raises this alert lives in a `Menu` that disappears the moment it is used, so the alert has to be hosted
/// by a view that lives as long as the window.

/// What a *Generate* run produced, as of the moment `publish()` returned.
///
/// Not `Result`: the failure carries an already-localized message rather than the `Error`, because that is all
/// the alert shows and it keeps the type free of the `any Error` that would otherwise cross into `@State`.
enum WebsiteGenerationOutcomeEnum: Equatable {

    /// Succeeded = the site is on disk.
    /// `pageCount` includes the landing page.
    /// The other three describe the translated towns and countries, taken from the Data package's
    /// `GeocodingCounts` just before the pages were generated, and before the geocoding that follows a Generate
    /// starts (#271); why before is explained at `publishAllLevels(preferences:)`.
    /// `completed` is how many were translated;
    /// `waiting` how many the published site lacks (at most);
    /// `placeholders` how many it shows as "Town?" or "Country?" for good.
    /// Plain `Ints` rather than the package struct itself,
    /// whose initializer is not public, so the previews could not build one.
    case succeeded(pageCount: Int, completed: Int, waiting: Int, placeholders: Int)

    /// Failed = publishing threw. `reason` is `localizedDescription`, shown verbatim.
    case failed(reason: String)

}

/// The completion alert, hosted by a view that outlives the Actions menu.
private struct WebsiteGenerationSupport: ViewModifier {

    /// Non-nil while the alert is up. Owned by the hosting view, which sets it when a generate finishes.
    @Binding var websiteGenerationOutcomeEnum: WebsiteGenerationOutcomeEnum?

    /// Needed only by the *Preview website* button, which honors `allowRemotePreview` like the menu item does.
    let preferences: PreferencesStructHTML

    /// Whether the site on disk can be previewed, shared with the menu item so both entry points follow one rule.
    let canPreviewWebsite: Bool

    /// Where a failure to start the preview server goes: the alert that
    /// ``SwiftUI/View/websitePreviewSupport(error:allowRemotePreview:)`` already hosts.
    /// Raising it from here is safe because this alert has dismissed by the time the button's action runs.
    @Binding var previewError: String?

    /// One alert with two faces. A single `.alert` rather than two mutually exclusive ones, so that success and
    /// failure cannot both be presented at once — which is what makes the "generate finished" state a single
    /// optional, and dismissal a single `nil`.
    private var title: String {
        if case .failed = websiteGenerationOutcomeEnum {
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

    /// The page count, then paragraphs about the town/country translations the pages were built with: one per
    /// kind of translation that is missing, or, with nothing missing, a plain statement that all are there.
    ///
    /// Each paragraph about what is missing appears only when its count is not zero, and starts with the symbol
    /// the footer uses for the same thing: ⏳ for translations still on their way, ⚠️ for ones that will not come.
    /// Separate strings rather than one string with optional parts, so that each can take its own plural form.
    /// The symbols are emoji because an alert message is plain text: an SF Symbol or a color would be dropped,
    /// while the emoji bring their own. They are added here, not in the String Catalog, because the ⚠️ sentence
    /// doubles as the footer's tooltip, which appears next to the footer's own ⚠️; the ⏳ follows suit.
    private func successMessage(pageCount: Int, completed: Int, waiting: Int, placeholders: Int) -> String {
        let pages = String(localized: "\(pageCount) pages were generated.",
                           table: "PhotoClubHubHTML.SwiftUI",
                           comment: "Alert message stating how many pages were generated")
        var warnings: [String] = []
        if waiting > 0 {
            warnings.append("⏳ " + String(localized: """
                                        \(waiting) locations are still being translated. Keep the app open \
                                        and generate again when the ⏳ at the bottom of the window is gone.
                                        """,
                                    table: "PhotoClubHubHTML.SwiftUI",
                                    comment: "Alert sentence: translations still being fetched after generating"))
        }
        if placeholders > 0 {
            warnings.append("⚠️ " + String(localized: """
                                        \(placeholders) locations cannot be translated \
                                        and will continue to show “Town?” or “Country?”.
                                        """,
                                    table: "PhotoClubHubHTML.SwiftUI",
                                    comment: "Alert sentence: translations that will stay as placeholders"))
        }

        if warnings.isEmpty == false {
            return ([pages] + warnings).joined(separator: "\n\n")
        }
        guard completed > 0 else { return pages } // no organizations or no languages: nothing to report
        return pages + "\n\n" + String(localized: "All \(completed) locations are translated.",
                                        table: "PhotoClubHubHTML.SwiftUI",
                                        comment: "Alert sentence: every town/country translation is in place")
    }

    func body(content: Content) -> some View {
        content
            .alert(title,
                   isPresented: Binding(get: { websiteGenerationOutcomeEnum != nil },
                                        set: { if !$0 { websiteGenerationOutcomeEnum = nil } }),
                   presenting: websiteGenerationOutcomeEnum) { outcome in
                if case .succeeded = outcome {
                    // Offered but disabled unless the site on disk can be previewed, rather than hidden: the
                    // button is worth seeing, because its absence would read as "previewing is gone" rather
                    // than "previewing does not apply to this build". Why only a localhost build qualifies is
                    // explained at `SiteOutput.isGeneratedForLocalhost()`, which `canPreviewWebsite` reflects.
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
                    .disabled(!canPreviewWebsite)

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
                    self.websiteGenerationOutcomeEnum = nil
                }
            } message: { outcome in
                switch outcome {
                case .succeeded(let pageCount, let completed, let waiting, let placeholders):
                    Text(successMessage(pageCount: pageCount, completed: completed,
                                        waiting: waiting, placeholders: placeholders))
                case .failed(let reason):
                    Text(verbatim: reason)
                }
            }
    }

}

extension View {

    /// Hosts the alert that reports the result of *Actions → Generate*. Apply to a view that lives as long as
    /// the window, not to the menu item — and alongside
    /// ``SwiftUI/View/websitePreviewSupport(error:allowRemotePreview:)``, whose alert this one's
    /// *Preview website* button reports into.
    func websiteGenerationSupport(outcome: Binding<WebsiteGenerationOutcomeEnum?>,
                                  preferences: PreferencesStructHTML,
                                  canPreviewWebsite: Bool,
                                  previewError: Binding<String?>) -> some View {
        modifier(WebsiteGenerationSupport(websiteGenerationOutcomeEnum: outcome,
                                          preferences: preferences,
                                          canPreviewWebsite: canPreviewWebsite,
                                          previewError: previewError))
    }

}

// Both faces of the alert, which are otherwise awkward to reach: the success one needs a full generate, and
// the failure one needs publish() to throw. Unreachable via ``ClubListView``'s own preview because that pulls
// in @FetchRequest views, which crash in Previews in this target (see the note in MembershipView.swift).
//
// The buttons are live: Show in Finder opens the real container, and Preview website starts the real server.
// The strings on the buttons below are deliberately verbatim — preview scaffolding is not localized.

// Believe it or not, these previews work, but are not particularly useful.

#Preview("Website generated alert") {
    @Previewable @State var outcome: WebsiteGenerationOutcomeEnum? =
        .succeeded(pageCount: 312, completed: 294, waiting: 0, placeholders: 0)
    @Previewable @State var previewError: String?

    Button {
        outcome = .succeeded(pageCount: 312, completed: 294, waiting: 0, placeholders: 0)
    } label: {
        Text(verbatim: "Raise the success alert again")
    }
    .frame(width: 320, height: 120)
    .websiteGenerationSupport(outcome: $outcome,
                              preferences: PreferencesStructHTML.defaultValue,
                              canPreviewWebsite: SiteOutput.isGeneratedForLocalhost(),
                              previewError: $previewError)
}

// While translations are still arriving: both extra sentences, and the plural "have" of the placeholder one.
#Preview("Website generated alert, translations incomplete") {
    @Previewable @State var outcome: WebsiteGenerationOutcomeEnum?
    @Previewable @State var previewError: String?

    Button {
        outcome = .succeeded(pageCount: 312, completed: 280, waiting: 12, placeholders: 2)
    } label: {
        Text(verbatim: "Raise the success alert with missing translations")
    }
    .frame(width: 320, height: 120)
    .websiteGenerationSupport(outcome: $outcome,
                              preferences: PreferencesStructHTML.defaultValue,
                              canPreviewWebsite: SiteOutput.isGeneratedForLocalhost(),
                              previewError: $previewError)
}

#Preview("Website generation failure alert") {
    @Previewable @State var outcome: WebsiteGenerationOutcomeEnum? =
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
                              canPreviewWebsite: SiteOutput.isGeneratedForLocalhost(),
                              previewError: $previewError)
}
