//
//  ExpertisesPage.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 10/10/2025.
//

import Ignite // for StaticPage
import CoreData // for ManagedObjectContext
import Photo_Club_Hub_Data // for language codes

struct ExpertisesPage: StaticPage {

    let languageID: String // ISO 639-1 code, e.g. "nl"
    var title: String { // needed by the StaticPage protocol
        String(localized: "Expertises",
               table: "PhotoClubHubHTML.Ignite",
               bundle: Bundle.forLanguage(languageID),
               comment: "Title of the Expertises index HTML page")
    }

    let showTemporaryExpertises: Bool = true // suppresses generating and showing table for temporary Expertises

    private var approvedExpertisesTable = Table {} // initialite to empty table, then fill during init()
    private var approvedExpertiseCount: Int = 0 // updated in makeTable(), Table doesn't support Table.count

    private var temporaryExpertisesTable = Table {} // initialite to empty table, then fill during init()
    private var temporaryExpertiseCount: Int = 0 // updated in makeTable(), Table doesn't support Table.count

    static func relativePath(languageID: String, expertiseID: String? = nil) -> String {
        if let expertiseID {
            return "\(languageID)/expertises/\(expertiseID)"
        } else {
            return "\(languageID)/expertises/"
        }
    }

    var path: String { "/\(Self.relativePath(languageID: languageID))" }
    var description: String { "List of expertises with description and some statistics" }

    // code using moc is executed via moc.performAndWait() and ends up running on the main thread (#1)

    // MARK: - init()

    init(moc: NSManagedObjectContext, language: String) {
        self.languageID = language

        let makeApprovedTableResult = makeExpertisesTable(approved: true, languageID: language, moc: moc)
        approvedExpertisesTable = makeApprovedTableResult.table
        approvedExpertiseCount = makeApprovedTableResult.expertiseCount

        if showTemporaryExpertises {
            let makeTemporaryTableResult = makeExpertisesTable(approved: false, languageID: language, moc: moc)
            temporaryExpertisesTable = makeTemporaryTableResult.table
            temporaryExpertiseCount = makeTemporaryTableResult.expertiseCount
        }
    }

    // MARK: - body()

    func body(context: PublishingContext) -> [BlockElement] {

        // MARK: - NavBar at bottom of screen

        SiteNavigationBar(languageID: languageID)

        // MARK: - approved Expertises

        Text {
            Badge(String(localized: "\(approvedExpertiseCount) approved expertise tags",
                         table: "PhotoClubHubHTML.Ignite",
                         bundle: Bundle.forLanguage(languageID),
                         comment: "Title badge at top of Expertises HTML index page"))
            .badgeStyle(.subtleBordered)
            .role(.success)
        }
        .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

        approvedExpertisesTable // Ignite Table where each Ignite Row represents an expertise
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

        Text(".").opacity(0) // didn't get padding() modifier to work
        Divider() // would like it in a darker color
            .padding(.vertical, 20)

        if showTemporaryExpertises {
            // MARK: - temporary Expertises

            Text {
                Badge(String(localized: "\(temporaryExpertiseCount) temporary expertise tags",
                             table: "PhotoClubHubHTML.Ignite",
                             bundle: Bundle.forLanguage(languageID),
                             comment: "Title badge at top of Expertises HTML index page"))
                .badgeStyle(.subtleBordered)
                .role(.info)
            }
            .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

            temporaryExpertisesTable // Ignite Table where each Ignite Row represents an expertise
                .tableStyle(.stripedRows)
                .tableBorder(true)
                .horizontalAlignment(.center)

        }

        FooterText(languageID: languageID)
    }

}
