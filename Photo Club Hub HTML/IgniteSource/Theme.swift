//
//  Theme.swift
//  Photo Club Hub - Ignite
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

                IgniteFooter() // "Created with Ignite"
                UpdatedOnFooter()
            }
        }
    }
}

struct UpdatedOnFooter: Component { // swiftlint doesn't want this one to be fileprivate, but it could be

    public func body(context: PublishingContext) -> [any PageElement] {
        let timezone = TimeZone.current
        let timezoneCode = timezone.abbreviation() ?? ""
        let date: String = Date.now.formatted(date: .abbreviated, time: .shortened)

        Alert {
            Text { // this is Ignite's Text, not SwiftUI's Text
                String(localized: "Data was last updated on \(date) \(timezoneCode).",
                       table: "Site",
                       comment: "Timestamp at bottom of static HTML page showing when page was generate")
            } .horizontalAlignment(.center)
        }
        .margin(.top, .small)
    }

}
