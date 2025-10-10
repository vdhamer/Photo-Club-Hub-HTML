//
//  Clubs+makeTable.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 15/02/2025.
//

import Ignite // for Table
import CoreData // for NSSortDescriptor
import Photo_Club_Hub_Data // for Organization

struct MakeClubsTableResult {
    let table: Table
    let clubsCount: Int
}

extension Clubs {

    // former: whether to list former members or current members
    // moc: use this CoreData Managed Object Context
    // club: for which club are we doing this?
    // return Int: count of returned members (can't directly count size of Ignite Table)
    // return Table: Ignite table containing rendering of requested members
    mutating func makeClubsTable(moc: NSManagedObjectContext) -> MakeClubsTableResult {
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
                        makeClubRow(moc: moc, club: club)
                    }
                }
                header: {
                    String(localized: "Town",
                           table: "PhotoClubHubHTML.Ignite", comment: "HTML table header for town column.")
                    String(localized: "Club name",
                           table: "PhotoClubHubHTML.Ignite", comment: "HTML table header for club name column.")
                    String(localized: "Members",
                           table: "PhotoClubHubHTML.Ignite", comment: "HTML table header for member count column.")
                    String(localized: "Club website",
                           table: "PhotoClubHubHTML.Ignite", comment: "HTML table header for clubs website link.")
                    String(localized: "Fotobond #",
                           table: "PhotoClubHubHTML.Ignite",
                           comment: "HTML table header for club's identifier in Fotobond.")
                    String(localized: "JSON",
                           table: "PhotoClubHubHTML.Ignite", comment: "HTML table header for link to JSON input file.")
                },
                clubsCount: -1234
            )
        } catch {
            fatalError("Failed to fetch memberPortfolios: \(error)")
        }

    }

    // generates an Ignite Row in an Ignite table
    // swiftlint:disable:next function_body_length
    fileprivate mutating func makeClubRow(moc: NSManagedObjectContext, club: Organization) -> Row {

        return Row {

            Column { // town
                Group {
                    Span(
                        String("\(club.town)")
                    )
//                    .hint(text: String(localized: "Where the club is based", table: "PhotoClubHubHTML.Ignite",
//                                       comment: "Hint text for the town column in the Clubs table"))
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // club name
                let url: String = "http://www.vdhamer.com/\(club.nickName)"
                Group {
                    if !club.members.isEmpty {
                        Text {
                            Link(String(club.fullName),
                                 target: url
                            )
                            .linkStyle(.hover)
                        } .font(.title5) .padding(.none) .margin(0)
//                            .hint(text: String(localized: "Click for list of members",
//                                               table: "PhotoClubHubHTML.Ignite",
//                                               comment: "Hint on club name Name column of Clubs table"))
                    } else {
                        club.fullName
                    }
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // member count
                let url: String = "http://www.vdhamer.com/\(club.nickName)"
                if !club.members.isEmpty {
                    Span(
                        Link(String("\(club.members.filter { !$0.isFormerMember }.count)"), target: url)
                            .linkStyle(.hover)
                    )
//                    .hint(text: String(localized: "Number of current members",
//                                       table: "PhotoClubHubHTML.Ignite",
//                                       comment: "Hint on numbers in Members column of Clubs table"))
                }
            } .verticalAlignment(.middle)

            Column { // website
                if club.organizationWebsite != nil {
                    Text {
                        Link(String(localized: "WebsiteSymbol",
                                    table: "PhotoClubHubHTML.Ignite",
                                    comment: "Text in cells in club website column"),
                             target: club.organizationWebsite!)
                        .linkStyle(.hover)
//                        .hint(text: String(localized: "Photoclub's website", table: "PhotoClubHubHTML.Ignite",
//                                           comment: "Hint on icon in Website column of Clubs table"))
                    } .font(.title5) .padding(.none) .margin(0)
                }
            } .verticalAlignment(.middle)

            Column { // Fotobond
                if club.fotobondNumber > 0 {
                    String("\(club.fotobondNumber)")
                        .margin(.leading, 10)
                }
            } .verticalAlignment(.middle)

            Column { // JSON
                if !club.members.isEmpty {
                    let url: String =
                        "https://github.com/vdhamer/Photo-Club-Hub/blob/main/JSON/\(club.nickName).level2.json"
                    Link(String("json"), target: url)
                }
            } .verticalAlignment(.middle)

        }

    }

    fileprivate func fullName(givenName: String,
                              infixName: String = "",
                              familyName: String) -> String {
        if infixName.isEmpty {
            return givenName + " " + familyName
        } else {
            return givenName + " " + infixName + " " + familyName
        }
    }

    fileprivate func lastPathComponent(fullUrl: String) -> String {
        let url = URL(string: fullUrl)
        let lastComponent: String = url?.lastPathComponent ?? "error in lastPathComponent"
        return "/images/\(lastComponent)"
    }

    fileprivate func describe(roles: [MemberRole: Bool?]) -> String {
        for role in roles {
            for definedRole in MemberRole.allCases {
                if role.key==definedRole && role.value==true {
                    return definedRole.localizedString(table: "PhotoClubHubHTML.Ignite").capitalized
                }
            }
        }
        return ""
    }

    func formatYears(_ years: Double) -> String {
        String(format: "%.1f", locale: Locale(identifier: "nl_NL"), years) // "1,2"
    }

}
