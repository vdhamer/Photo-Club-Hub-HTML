//
//  ClubsPage+makeClubsTable.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 15/02/2025.
//

import Ignite // for Table
import CoreData // for NSSortDescriptor
import Photo_Club_Hub_Data // for Organization

struct MakeClubsTableResult {
    let table: Table // Table is an Ignite Table
    let clubsCount: Int
}

extension ClubsPage {

    /// Builds the clubs table from Core Data.
    ///
    /// Fetches `Organization` entities of type `.club`, sorted by town and name,
    /// and returns an Ignite `Table` plus the number of clubs returned.
    /// - Parameters:
    ///   - moc: The Core Data managed object context used for fetching.
    ///   - languageID: ISO 639-1 language code used for localization and internal link paths.
    /// - Returns: `MakeClubsTableResult` containing the rendered table and club count.
    mutating func makeClubsTable(moc: NSManagedObjectContext, languageID: String) -> MakeClubsTableResult {
        do {
            // match sort order used in MembershipView to generate MembershipView SwiftUI view
            let sortDescriptor1 = NSSortDescriptor(keyPath: \Organization.town_, ascending: true)
            let sortDescriptor2 = NSSortDescriptor(keyPath: \Organization.fullName_, ascending: true)

            let fetchRequest: NSFetchRequest<Organization> = Organization.fetchRequest()
            fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]

            fetchRequest.predicate = NSPredicate(format: "organizationType_.organizationTypeName_ = %@",
                                                 argumentArray: [OrganizationTypeEnum.club.rawValue])
            let clubs: [Organization] = try moc.fetch(fetchRequest)

            return MakeClubsTableResult(
                table: Table {
                    for club in clubs {
                        makeClubRow(moc: moc, club: club, languageID: languageID)
                    }
                }
                header: {
                    String(localized: "Town",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for town column.")
                    String(localized: "Club name",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for club name column.")
                    String(localized: "Members",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for member count column.")
                    String(localized: "Club website",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for clubs website link.")
                    String(localized: "Fotobond #",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for club's identifier in Fotobond.")
                    String(localized: "JSON",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for link to JSON input file.")
                },
                clubsCount: clubs.count
            )
        } catch {
            fatalError("Failed to fetch clubs: \(error)")
        }

    }

    // generates an Ignite Row in an Ignite table
    // swiftlint:disable:next function_body_length
    private mutating func makeClubRow(moc: NSManagedObjectContext, club: Organization, languageID: String) -> Row {

        return Row { // Ignite Row

            Column { // town
                Group {
                    Span(
                        String("\(club.town)".replacingUTF8Diacritics)
                    )
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // club name
                let membershipListPath: String? = club.members.isEmpty ? nil :
                    Members.relativePath(languageID: languageID, clubNickname: club.nickName)
                Group {
                    if let membershipListPath {
                        Text {
                            Link(String(club.fullName.replacingUTF8Diacritics),
                                 target: "/\(membershipListPath)"
                            )
                            .linkStyle(.hover)
                        } .font(.title5) .padding(.none) .margin(0)
                    } else {
                        club.fullName.replacingUTF8Diacritics
                    }
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // member count for this club
                let membershipListPath = Members.relativePath(languageID: languageID, clubNickname: club.nickName)
                if !club.members.isEmpty {
                    Span(
                        Link(String("\(club.members.filter { !$0.isFormerMember }.count)"),
                             target: "/\(membershipListPath)")
                            .linkStyle(.hover)
                    )
                }
            } .verticalAlignment(.middle)

            Column { // website
                if club.organizationWebsite != nil {
                    Text {
                        Link(String(localized: "🌐",
                                    table: "PhotoClubHubHTML.Ignite",
                                    comment: "Unicode globe symbol in cells in club website column"),
                             target: club.organizationWebsite!)
                        .linkStyle(.hover)
                    } .font(.title5) .padding(.none) .margin(0)
                }
            } .verticalAlignment(.middle)

            Column { // Fotobond
                if let fotobondClubNumber = club.fotobondClubNumber {
                    String(fotobondClubNumber.display) // Int16 301 is displayed as 0301, nil is displayed as "-"
                } else {
                    String("-")
                }
            }
                .verticalAlignment(.middle)
                .margin(.leading, 10)

            Column { // JSON
                if !club.members.isEmpty {
                    let url: String =
                        "https://github.com/vdhamer/Photo-Club-Hub/blob/main/JSON/\(club.nickName).level2.json"
                    Link(String("json"), target: url)
                }
            } .verticalAlignment(.middle)

        }

    }

}
