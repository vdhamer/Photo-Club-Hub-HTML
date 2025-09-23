//
//  Clubs.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Ignite // for StaticPage
import CoreData // for ManagedObjectContext
import SwiftImageReadWrite // for image format conversion
import Photo_Club_Hub_Data // for Organization

struct Clubs: StaticPage {
    var title = "Fotoclubs"  // needed by the StaticPage protocol, but how do I localize it?

    fileprivate var clubsTable = Table {} // initialite to empty table, then fill during init()

    // code using moc is executed via moc.performAndWait() and ends up running on the main thread (#1)

    // MARK: - init()

    init(moc: NSManagedObjectContext) {
        clubsTable = makeClubsTable(moc: moc).table
    }

    // MARK: - body()

    func body(context: PublishingContext) -> [BlockElement] {

        // MARK: - current members

        Text {
            Badge(String(localized: "Photo clubs",
                         table: "PhotoClubHubHTML.Ignite", comment: "Title badge at top of Clubs HTML index page"))
                .badgeStyle(.subtleBordered)
                .role(.success)
        }
        .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

        clubsTable // this is an Ignite Table that renders an array of Ignite Rows, each representing a club
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

    }

}
