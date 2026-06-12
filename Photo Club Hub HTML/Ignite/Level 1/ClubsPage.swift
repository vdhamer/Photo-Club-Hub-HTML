//
//  ClubsPage.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Ignite // for StaticPage
import CoreData // for ManagedObjectContext

/// Static page that lists photo clubs as an HTML table.
/// Builds this table from Core Data within the init()
/// and renders it using Ignite blocks when body() is called by Ignite.
struct ClubsPage: StaticPage {

    let languageID: String // ISO 639-1 code, e.g. "nl"
    var title: String { // needed by the StaticPage protocol
        String(localized: "Photo clubs",
               table: "PhotoClubHubHTML.Ignite",
               bundle: Bundle.forLanguage(languageID),
               comment: "Title of the Clubs index HTML page")
    }

    private var clubsTable = Table {} // initialized as empty Ignite table, that gets filled during init()
    private var clubsCount: Int = 0

    static func relativePath(languageID: String) -> String { "\(languageID)/clubs/" }
    var path: String { "/\(Self.relativePath(languageID: languageID))" }

    // code using moc is executed via moc.performAndWait() and ends up running on the main thread (#1)

    // MARK: - init()

    init(moc: NSManagedObjectContext, language: String) {
        self.languageID = language
        let result = makeClubsTable(moc: moc, languageID: language)
        clubsTable = result.table
        clubsCount = result.clubsCount
    }

    // MARK: - body()

    func body(context: PublishingContext) -> [BlockElement] {

        // MARK: - Links

        SiteNavigationBar(languageID: languageID)

        // MARK: - current members

        Text {
            Badge(String(localized: "\(clubsCount) photo clubs",
                         table: "PhotoClubHubHTML.Ignite",
                         bundle: Bundle.forLanguage(languageID),
                         comment: "Title badge at top of Clubs HTML index page"))
                .badgeStyle(.subtleBordered)
                .role(.success)
        }
        .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

        clubsTable // this is an Ignite Table that renders an array of Ignite Rows, each representing a club
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

        FooterText(languageID: languageID)
    }

}
