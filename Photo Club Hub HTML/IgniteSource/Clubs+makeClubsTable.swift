//
//  Clubs+makeTable.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 15/02/2025.
//

import Ignite // for Table
import CoreData // for NSSortDescriptor
import AppKit // for CGImage
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
//            fetchRequest.predicate = NSPredicate(format: "TRUEPREDICATE")
            let clubs: [Organization] = try moc.fetch(fetchRequest)

            return MakeClubsTableResult(
                table: Table {
                    for club in clubs {
                        makeClubRow(moc: moc, club: club)
                    }
                }
                header: {
                    String(localized: "Town",
                           table: "HTML", comment: "HTML table header for town column.")
                    String(localized: "Club name",
                           table: "HTML", comment: "HTML table header for club name column.")
                    String(localized: "Members",
                           table: "HTML", comment: "HTML table header for member count column.")
                    String(localized: "Club web site",
                           table: "HTML", comment: "HTML table header for clubs website link.")
                    String(localized: "Fotobond #",
                           table: "HTML", comment: "HTML table header for club's identifier in Fotobond.")
                    String(localized: "JSON",
                           table: "HTML", comment: "HTML table header for link to JSON input file.")
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
                    .hint(text: "Where the club is based")
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // club name
                let url: String = "http://www.vdhamer.com/\(club.nickname)"
                Group {
                    Text {
                        if !club.members.isEmpty {
                            Link(String(club.fullName),
                                target: url
                            )
                                .linkStyle(.hover)
                        } else {
                            club.fullName
                        }
                    } .font(.title5) .padding(.none) .margin(0)
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // Membership
                if !club.members.isEmpty {
                    Span(
                        String("\(club.members.count)")
                    )
                    .hint(text: "Leden inclusief ex-leden")
                }
            }

            Column { // web site
                if club.organizationWebsite != nil {
                    Link("web site", target: club.organizationWebsite!)
                }
            } .verticalAlignment(.middle)

            Column { // Fotobond #
                if club.fotobondNumber > 0 {
                    String("\(club.fotobondNumber)")
                        .margin(.leading, 10)
                }
            } .verticalAlignment(.middle)

            Column { // JSON
                if !club.members.isEmpty {
                    let url: String =
                        "https://github.com/vdhamer/Photo-Club-Hub/blob/main/JSON/\(club.nickname).level2.json"
                    Link(String("json"), target: url)
                }
            } .verticalAlignment(.middle)

        }

        // Returns Ignite PageElement rendering the lists of official or unoffiical Expertise tags.
        func generatePageElements(localizedExpertiseResultLists: LocalizedExpertiseResultLists, isStandard: Bool)
                                  -> PageElement? {
            let localizedExpertiseResultList = isStandard ? localizedExpertiseResultLists.standard :
                                                          localizedExpertiseResultLists.nonstandard
            guard !localizedExpertiseResultList.list.isEmpty else { return nil } // nothing to display

            var hint: String?
            var customHint: String = ""
            var string = localizedExpertiseResultLists.getIconString(standard: isStandard) // line starts with icon

            for localizedExpertiseResult in localizedExpertiseResultList.list {
                string.append(" " + localizedExpertiseResult.name
                              + localizedExpertiseResult.delimiterToAppend)
                hint = localizedExpertiseResult.localizedExpertise?.usage
                customHint = localizedExpertiseResult.customHint ?? ""
            }

            if !isStandard {
                if hint == nil && customHint == "" {
                    return Text(string)
                        .horizontalAlignment(.leading)
                        .padding(.none)
                        .margin(5)
                        .hint(text: String(localized: "Unofficial expertise. It has no translations yet.",
                                           table: "Package",
                                           comment: "Hint for expertise without localization"))
                } else {
                    return Text(string)
                        .horizontalAlignment(.leading)
                        .padding(.none)
                        .margin(5)
                        .hint(text: String(localized: "Expertises: \(customHint)",
                                           table: "Package",
                                           comment: "Hint when providing too many expertises"))
                }
            } else {
                if hint != nil {
                    return Text(string)
                        .horizontalAlignment(.leading)
                        .padding(.none)
                        .margin(5)
                        .hint(text: hint!)
                } else {
                    return Text(string)
                        .horizontalAlignment(.leading)
                        .padding(.none)
                        .margin(5)
                }
            }
        }

    }

    fileprivate func customHint(localizedExpertiseResults: [LocalizedExpertiseResult]) -> String {
        var hint: String = ""

        for localizedExpertiseResult in localizedExpertiseResults {
            if localizedExpertiseResult.localizedExpertise != nil {
                hint.append(getIconString(standard: true) + " " +
                            localizedExpertiseResult.localizedExpertise!.name + " ")
            } else {
                hint.append(getIconString(standard: true) + " " + localizedExpertiseResult.id + " ")
            }
        }

        return hint.trimmingCharacters(in: CharacterSet(charactersIn: " "))
    }

    fileprivate func getIconString(standard: Bool) -> String {
        let temp = LocalizedExpertiseResultLists(standardList: [], nonstandardList: [])
        return standard ? temp.standard.icon : temp.nonstandard.icon
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
                    return definedRole.localizedString().capitalized
                }
            }
        }
        return ""
    }

    fileprivate mutating func formatMembershipYears(start: Date?, end: Date?,
                                                    isFormer: Bool,
                                                    fotobond: Int?) -> Span {
        var years = TimeInterval(0)

        if start != nil {
            let end: Date = (end != nil) ? end! : Date.now // optional -> not optional
            let dateInterval = DateInterval(start: start!, end: end)
            years = dateInterval.duration / (365.25 * 24 * 60 * 60)
        }

        let fotobondString: String
        if showFotobondNumber, let fotobond {
            fotobondString = " Fotobond #\(fotobond)"
        } else {
            fotobondString = ""
        }

        let unknown = Span(String(localized: "-",
                                  table: "HTML",
                                  comment: "Shown in member table when start date unavailable"))

        if isFormer == false { // if current member, displays "Member for NN.N years"
            guard start != nil else { return unknown }

            currentMembersTotalYears += years
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let formattedStartDate = dateFormatter.string(from: start!)
            return Span(String(localized: "Member for past \(formatYears(years)) years",
                        table: "HTML",
                        comment: "Membership duration for current members"))
                .hint(text: String(localized:
                                   """
                                   From \(formattedStartDate)\(fotobondString)
                                   """,
                                   table: "HTML",
                                   comment: "Mouseover hint on cell containing start-end years"))
        } else { // if current member, displays "Member from YYYYY to YYYY"
            formerMembersTotalYears += years
            guard end != nil && start != nil else { return unknown }
            return Span(String(localized: "Member from \(toYear(date: start!)) to \(toYear(date: end!))",
                               table: "HTML",
                               comment: "Membership duration for current members"))
                .hint(text: String(localized:
                                   """
                                   From \(toYear(date: start!)) to \(toYear(date: end!)) (\(formatYears(years)) years)\
                                   \(fotobondString)
                                   """,
                                   table: "HTML",
                                   comment: "Mouseover hint on cell containing start-end years"))
        }
    }

    func formatYears(_ years: Double) -> String {
        String(format: "%.1f", locale: Locale(identifier: "nl_NL"), years) // "1,2"
    }

    fileprivate func toYear(date: Date) -> String {
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: date) // "2020"
    }

}
