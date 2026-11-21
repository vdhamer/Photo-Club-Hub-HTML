//
//  SiteNavigationBar.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 12/06/2026.
//

import Ignite // for NavigationBar, Link, Button, Image, Dropdown, BlockElement
import Foundation // for Bundle

/// An Ignite localized navigation bar shown at the bottom of every generated HTML page.
///
/// Conforms to `BlockElement` so it can be placed directly inside a page's `body()` method,
/// mirroring the pattern used by `FooterText`.
struct SiteNavigationBar: BlockElement {
    let pageLanguageID: String // ISO 639-1 code, e.g. "nl" — selects the translation bundle

    /// Required by `PageElement` (via `BlockElement`). `SiteNavigationBar` never applies CSS modifiers,
    /// so the getter returns a fresh default value borrowed from another element — the only way to
    /// obtain a `CoreAttributes` value outside the Ignite module, whose initializer is internal.
    /// The setter is intentionally discarded because mutations would be lost anyway (no stored backing).
    var attributes: CoreAttributes { get { Text("").attributes } set { _ = newValue } }

    /// Required by `BlockElement`. `.automatic` lets Ignite decide based on context.
    var columnWidth: ColumnWidth = .automatic

    func render(context: PublishingContext) -> String {
        let pageLanguageBundle = Bundle.forLanguage(pageLanguageID)
        let navBar = NavigationBar(
                logo: Button(label: {
                    Image("/images/AppIcon.png", description: "App icon")
                        .resizable()
                        .frame(width: 40)
                        .padding(.trailing, 15)
                    String(localized: "Photo Club Hub network",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: pageLanguageBundle,
                           comment: "Mentioned at start of navigation bar")
                })
                .role(.secondary)
                .buttonSize(.small)
        ) { // items:

            Link(String(localized: "Photo clubs",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: pageLanguageBundle,
                        comment: "Button linking to Clubs page"),
                 target: "/\(pageLanguageID)/clubs")
            .linkStyle(.hover)
            .role(.primary)

            Link(String(localized: "Photo Museums",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: pageLanguageBundle,
                        comment: "Button linking to Museums list page"),
                 target: "/\(pageLanguageID)/museums")
            .linkStyle(.hover)
            .role(.primary)

            Link(String(localized: "Expertises",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: pageLanguageBundle,
                        comment: "Button linking to Expertise list page"),
                 target: "/\(ExpertisesPage.relativePath(languageID: pageLanguageID))")
            .linkStyle(.hover)
            .role(.primary)

            // No Stats item: the page it linked to, /<lang>/statistics, is not generated, so the
            // menu offered a 404 on every page (HTML#263). Restore this when a StatisticsPage
            // exists, and take its target from `StatisticsPage.relativePath(languageID:)` rather
            // than a literal, the way every other item here does. A hardcoded path is what let
            // this point at nothing in the first place.

            documentationDropdown(pageLanguageBundle: pageLanguageBundle).dropup()

        }
           .navigationItemAlignment(.trailing)
           .navigationBarStyle(.light)
           .position(.fixedBottom)
           .background(.antiqueWhite.opacity(0.75))

        return navBar.render(context: context)
    }

    private func documentationDropdown(pageLanguageBundle: Bundle) -> Dropdown {
        Dropdown(String(localized: "Documentation",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: pageLanguageBundle,
                        comment: "Menu item for downdrop with links to documentation")) {
            Link("Photo Club Hub",
                 target: URL("""
                             https://github.com/vdhamer/\
                             Photo-Club-Hub/blob/main/.github/\
                             README.md#photo-club-hub
                             """))
                .linkStyle(.button)
                .buttonSize(.small)
                .role(.secondary)

            Link("Photo Club Hub HTML",
                 target: URL("""
                             https://github.com/vdhamer/\
                             Photo-Club-Hub-HTML/blob/main/.github/\
                             README.md#photo-club-hub-html
                             """))
                .linkStyle(.button)
                .buttonSize(.small)
                .role(.secondary)

            Link(String(localized: "FAQ",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: pageLanguageBundle,
                        comment: "Button linking to Dutch language FAQ for Photo Club Hub"),
                 target: URL("https://tinyurl.com/fchFAQnl"))
                .linkStyle(.button)
                .role(.primary)

            Link(String(localized: "IgniteLink",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: pageLanguageBundle,
                        comment: "Menu item for documentation about twostraws/Ignite"),
                 target: URL("https://swiftpackageindex.com/twostraws/Ignite"))
                .linkStyle(.button)
                .buttonSize(.small)
                .role(.secondary)
        }
    }

}
