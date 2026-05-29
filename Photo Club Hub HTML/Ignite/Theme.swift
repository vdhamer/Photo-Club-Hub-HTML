//
//  Theme.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Ignite // for Theme

struct MyTheme: Theme {
    func render(page: Page, context: PublishingContext) -> HTML {
        HTML {
            Head(for: page, in: context, additionalItems: {
                MetaTag(name: "referrer", content: "no-referrer") // for sites that try to block hot-linking
            })

            Body {
                page.body
            }
        }
    }
}
