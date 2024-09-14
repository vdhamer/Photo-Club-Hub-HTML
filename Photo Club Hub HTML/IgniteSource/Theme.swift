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

private struct UpdatedOnFooter: Component {
    public init() { }

    public func body(context: PublishingContext) -> [any PageElement] {
        let timezone = TimeZone.current
        let timezoneCode = timezone.abbreviation() ?? ""

        Alert {
            Text {
                "Data was last updated on \(Date.now.formatted(date: .long, time: .shortened)) \(timezoneCode)."
            } .horizontalAlignment(.center)
        }
        .margin(.top, .small)
    }
}
