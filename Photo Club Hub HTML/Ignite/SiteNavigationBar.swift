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
    let languageID: String // ISO 639-1 code, e.g. "nl" — selects the translation bundle

    /// Required by `PageElement` (via `BlockElement`). `SiteNavigationBar` never applies CSS modifiers,
    /// so the getter returns a fresh default value borrowed from another element — the only way to
    /// obtain a `CoreAttributes` value outside the Ignite module, whose initializer is internal.
    /// The setter is intentionally discarded because mutations would be lost anyway (no stored backing).
    var attributes: CoreAttributes { get { Text("").attributes } set { _ = newValue } }

    /// Required by `BlockElement`. `.automatic` lets Ignite decide based on context.
    var columnWidth: ColumnWidth = .automatic

    func render(context: PublishingContext) -> String {
        let languageBundle = Bundle.forLanguage(languageID)
        let navBar = NavigationBar(
                logo: Button(label: {
                    Image("/images/AppIcon.png", description: "App icon")
                        .resizable()
                        .frame(width: 40)
                        .padding(.trailing, 15)
                    String(localized: "Photo Club Hub network",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: languageBundle,
                           comment: "Mentioned at start of navigation bar")
                })
                .role(.secondary)
                .buttonSize(.small)
        ) { // items:

            Link(String(localized: "Photo clubs",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: languageBundle,
                        comment: "Button linking to Clubs page"),
                 target: "/\(languageID)/clubs")
            .linkStyle(.hover)
            .role(.primary)

            Link(String(localized: "Photo Museums",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: languageBundle,
                        comment: "Button linking to Museums list page"),
                 target: "/\(languageID)/museums")
            .linkStyle(.hover)
            .role(.primary)

            Link(String(localized: "Expertises",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: languageBundle,
                        comment: "Button linking to Expertise list page"),
                 target: "/\(ExpertisesPage.relativePath(languageID: languageID))")
            .linkStyle(.hover)
            .role(.primary)

            Link(String(localized: "Stats",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: languageBundle,
                        comment: "Button linking to page with statistics"),
                 target: "/\(languageID)/statistics")
            .linkStyle(.hover)
            .role(.primary)

            documentationDropdown(languageBundle: languageBundle).dropup()

        }
           .navigationItemAlignment(.trailing)
           .navigationBarStyle(.light)
           .position(.fixedBottom)
           .background(.antiqueWhite.opacity(0.75))

        return navBar.render(context: context)
    }

    private func documentationDropdown(languageBundle: Bundle) -> Dropdown {
        Dropdown(String(localized: "Documentation",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: languageBundle,
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
                             README.md#photo-club-hub-html"
                             """))
                .linkStyle(.button)
                .buttonSize(.small)
                .role(.secondary)

            Link(String(localized: "FAQ",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: languageBundle,
                        comment: "Button linking to Dutch language FAQ for Photo Club Hub"),
                 target: URL("https://tinyurl.com/fchFAQnl"))
                .linkStyle(.button)
                .role(.primary)

            Link(String(localized: "IgniteLink",
                        table: "PhotoClubHubHTML.Ignite",
                        bundle: languageBundle,
                        comment: "Menu item for documentation about twostraws/Ignite"),
                 target: URL("https://swiftpackageindex.com/twostraws/Ignite"))
                .linkStyle(.button)
                .buttonSize(.small)
                .role(.secondary)
        }
    }

}
