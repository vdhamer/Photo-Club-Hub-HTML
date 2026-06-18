//
//  ClubsPage.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Ignite // for StaticPage
import CoreData // for ManagedObjectContext
import Photo_Club_Hub_Data // for OrganizationTypeEnum

/// Static page that lists photo clubs or museums as an HTML table.
/// Builds this table from Core Data within the init()
/// and renders it using Ignite blocks when body() is called by Ignite.
struct ClubsPage: StaticPage {

    let languageID: String // ISO 639-1 code, e.g. "nl"
    let organizationType: OrganizationTypeEnum // e.g. .club or .museum

    var title: String { // needed by the StaticPage protocol
        switch organizationType {
        case .museum:
            String(localized: "Photo Museums",
                   table: "PhotoClubHubHTML.Ignite",
                   bundle: Bundle.forLanguage(languageID),
                   comment: "Title of the Museums index HTML page")
        default:
            String(localized: "Photo clubs",
                   table: "PhotoClubHubHTML.Ignite",
                   bundle: Bundle.forLanguage(languageID),
                   comment: "Title of the Clubs index HTML page")
        }
    }

    private var clubsTable = Table {} // initialized as empty Ignite table, filled during init()
    private var count: Int = 0
    private var badgeLabel: String = ""

    static func relativePath(languageID: String, organizationType: OrganizationTypeEnum = .club) -> String {
        switch organizationType {
        case .museum: return "\(languageID)/museums/"
        default: return "\(languageID)/clubs/"
        }
    }

    var path: String { "/\(Self.relativePath(languageID: languageID, organizationType: organizationType))" }

    // MARK: - init()

    init(moc: NSManagedObjectContext, language: String, organizationType: OrganizationTypeEnum = .club) {
        self.languageID = language
        self.organizationType = organizationType
        let bundle = Bundle.forLanguage(language)
        let result = makeClubsTable(moc: moc, languageID: language)
        clubsTable = result.table
        count = result.count
        switch organizationType {
        case .museum:
            badgeLabel = String(localized: "\(result.count) photo museums",
                               table: "PhotoClubHubHTML.Ignite",
                               bundle: bundle,
                               comment: "Title badge at top of Museums HTML index page")
        default:
            badgeLabel = String(localized: "\(result.count) photo clubs",
                               table: "PhotoClubHubHTML.Ignite",
                               bundle: bundle,
                               comment: "Title badge at top of Clubs HTML index page")
        }
    }

    // MARK: - body()

    func body(context: PublishingContext) -> [BlockElement] {

        SiteNavigationBar(languageID: languageID)

        Text {
            Badge(badgeLabel)
                .badgeStyle(.subtleBordered)
                .role(.success)
        }
        .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

        clubsTable // Ignite Table that renders an array of Ignite Rows, each representing an organization
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

        FooterText(languageID: languageID)
    }

}
