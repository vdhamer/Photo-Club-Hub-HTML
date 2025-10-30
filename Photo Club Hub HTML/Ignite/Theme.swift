//
//  Theme.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Foundation // for Date
import Ignite // for Theme

struct MyTheme: Theme {
    func render(page: Page, context: PublishingContext) -> HTML {
        HTML {
            Head(for: page, in: context)

            Body {
                page.body

                FooterText()
            }
        }
    }
}

struct FooterText: Component { // swiftlint doesn't want this one to be fileprivate, but it could be

    public func body(context: PublishingContext) -> [any PageElement] {
        let timezone = TimeZone.current
        let timezoneCode = timezone.abbreviation() ?? ""
        let date: String = Date.now.formatted(date: .abbreviated, time: .shortened)
        let fch = String(localized: "Photo Club Hub", table: "PhotoClubHubHTML.Ignite", bundle: .main,
                         comment: "For footer that says 'This page was last updated on ... by ...'")

        Alert {
            Text { // this is Ignite's Text, not SwiftUI's Text
                String(localized: """
                                  This page is part of the \(fch) network \
                                  and was last updated on \(date) \(timezoneCode).
                                  """,
                       table: "PhotoClubHubHTML.Ignite",
                       bundle: .main, // actually the default
                       comment: "Timestamp at bottom of static HTML page showing when page was generate")
            }
            .horizontalAlignment(.center)
        }
        .margin(.top, .small)
    }

}
