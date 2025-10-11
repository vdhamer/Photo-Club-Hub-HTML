//
//  Expertises.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 10/10/2025.
//

import Ignite // for StaticPage
import CoreData // for ManagedObjectContext

struct Expertises: StaticPage {
    var title = "Fotoclubs"  // needed by the StaticPage protocol, but how do I localize it?
    let showUnapprovedExpertises: Bool = true // suppresses generating and showing table for unapproved Expertises

    fileprivate var approvedExpertisesTable = Table {} // initialite to empty table, then fill during init()
    fileprivate var unapprovedExpertisesTable = Table {} // initialite to empty table, then fill during init()
    fileprivate var approvedExpertiseCount: Int = 0 // updated in makeTable(), Table doesn't support Table.count
    fileprivate var unapprovedExpertiseCount: Int = 0 // updated in makeTable(), Table doesn't support Table.count

    // code using moc is executed via moc.performAndWait() and ends up running on the main thread (#1)

    // MARK: - init()

    init(moc: NSManagedObjectContext) {
        let makeTableResult = makeExpertisesTable(approved: true, moc: moc)
        approvedExpertisesTable = makeTableResult.table
        approvedExpertiseCount = makeTableResult.expertiseCount
        if showUnapprovedExpertises {
            let makeTableResult = makeExpertisesTable(approved: false, moc: moc)
            unapprovedExpertisesTable = makeTableResult.table
            unapprovedExpertiseCount = makeTableResult.expertiseCount
        }
    }

    // MARK: - body()

    func body(context: PublishingContext) -> [BlockElement] {

        // MARK: - approved Expertises

        Text {
            Badge(String(localized: "\(approvedExpertiseCount) approved expertise tags",
                         table: "PhotoClubHubHTML.Ignite", comment: "Title badge at top of Expertises HTML index page"))
                .badgeStyle(.subtleBordered)
                .role(.success)
        }
        .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

        approvedExpertisesTable // Ignite Table that renders an array of Ignite Rows, each representing an expertise
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

        Text(".") // didn't get padding() modifier to work
        Divider() // would like it in a darker color
            .padding(.vertical, 20)

        // MARK: - unapproved Expertises

        Text {
            Badge(String(localized: "\(unapprovedExpertiseCount) unapproved expertise tags",
                         table: "PhotoClubHubHTML.Ignite", comment: "Title badge at top of Expertises HTML index page"))
                .badgeStyle(.subtleBordered)
                .role(.info)
        }
        .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

        approvedExpertisesTable // Ignite Table that renders an array of Ignite Rows, each representing an expertise
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

    }

}
