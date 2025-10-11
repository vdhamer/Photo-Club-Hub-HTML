//
//  Expertises+makeExpertisesTable.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 10/10/2025.
//

import Ignite // for Table
import CoreData // for NSSortDescriptor
import Photo_Club_Hub_Data // for Expertise

struct MakeExpertisesTableResult {
    let table: Table
    let expertisesCount: Int
}

extension Expertises {

    // moc: use this CoreData Managed Object Context
    // expertise: for which expertise are we doing this?
    // return Int: count of returned members (can't directly count size of Ignite Table)
    // return Table: Ignite table containing rendering of requested members
    mutating func makeExpertisesTable(moc: NSManagedObjectContext) -> MakeExpertisesTableResult {
        do {
            // match sort order used in MembershipView to generate MembershipView SwiftUI view
            let sortDescriptor = NSSortDescriptor(keyPath: \Expertise.id_, ascending: true)

            let fetchRequest: NSFetchRequest<Expertise> = Expertise.fetchRequest()
            fetchRequest.sortDescriptors = [sortDescriptor]

            let allPredicate = NSPredicate(format: "TRUEPREDICATE")
            fetchRequest.predicate = allPredicate
            let expertises: [Expertise] = try moc.fetch(fetchRequest)

            return MakeExpertisesTableResult(
                table: Table {
                    for expertise in expertises {
                        makeExpertiseRow(moc: moc, expertise: expertise)
                    }
                }
                header: {
                    String(localized: "Idenfifier",
                           table: "PhotoClubHubHTML.Ignite", comment: "HTML table header for town column.")
                    String(localized: "Localized name",
                           table: "PhotoClubHubHTML.Ignite", comment: "HTML table header for club name column.")
                    String(localized: "Description",
                           table: "PhotoClubHubHTML.Ignite", comment: "HTML table header for club name column.")
                },
                expertisesCount: -1234
            )
        } catch {
            fatalError("Failed to fetch memberPortfolios: \(error)")
        }

    }

    // generates an Ignite Row in an Ignite table
    fileprivate mutating func makeExpertiseRow(moc: NSManagedObjectContext, expertise: Expertise) -> Row {

        return Row {

            Column { // club name
                let url: String = "https://www.fgDeGender.nl/\(expertise.id)"
                Group {
                    Text {
                        Link(String(expertise.id),
                             target: url
                        )
                        .linkStyle(.hover)
                    } .font(.title5) .padding(.none) .margin(0)
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // town
                Group {
                    Span(
                        String("\(expertise.id)")
                    )
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // club name
                let url: String = "https://www.fgDeGender.nl/\(expertise.id)"
                Group {
                    Text {
                        Link(String(expertise.id),
                             target: url
                        )
                        .linkStyle(.hover)
                    } .font(.title5) .padding(.none) .margin(0)
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

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

}
