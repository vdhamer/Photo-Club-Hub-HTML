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
    let expertiseCount: Int
}

extension ExpertisesPage {

    // moc: use this CoreData Managed Object Context
    // expertise: for which expertise are we doing this?
    // return Int: count of returned members (can't directly count size of Ignite Table)
    // return Table: Ignite table containing rendering of requested members
    mutating func makeExpertisesTable(approved: Bool,
                                      languageID: String,
                                      moc: NSManagedObjectContext) -> MakeExpertisesTableResult {
        do {
            // allow coredata
            let sortDescriptors = approved ? [] : [NSSortDescriptor(keyPath: \Expertise.id_, ascending: true)]

            let fetchRequest: NSFetchRequest<Expertise> = Expertise.fetchRequest()
            fetchRequest.sortDescriptors = sortDescriptors

            fetchRequest.predicate = NSPredicate(format: "isSupported == %@", NSNumber(value: approved))
            var expertises: [Expertise] = try moc.fetch(fetchRequest)
            if approved { // sort result in memory when there is a translation available
                expertises.sort { lhs, rhs in
                    return lhs.selectedLocalizedExpertise(isoCode: languageID).name <
                           rhs.selectedLocalizedExpertise(isoCode: languageID).name
                }
            }

            return MakeExpertisesTableResult(
                table: Table {
                    for expertise in expertises {
                        makeExpertiseRow(moc: moc, expertise: expertise, languageID: languageID)
                    }
                }
                header: {
                    String(localized: "Expertise",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for exertise name column.")
                    String(localized: "Description",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for the description column.")
                    String(localized: "Idenfifier",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for the ID column.")
                },
                expertiseCount: expertises.count
            )
        } catch {
            fatalError("Failed to fetch Expertises: \(error)")
        }

    }

    // generates an Ignite Row in an Ignite table
    private mutating func makeExpertiseRow(moc: NSManagedObjectContext,
                                           expertise: Expertise,
                                           languageID: String) -> Row {

        return Row {

            Column { // localized name
                let url: String = "/\(ExpertisesPage.relativePath(languageID: languageID, expertiseID: expertise.id))/"
                Group {
                    Text {
                        Link(String(expertise.isSupported ?
                                    "\(expertise.selectedLocalizedExpertise(isoCode: languageID).name)" :
                                    String(expertise.id))
                             + String(" (\(PhotographerExpertise.count(context: moc, expertiseID: expertise.id))x)"),
                             target: url
                        )
                        .linkStyle(.hover)
                    } .font(.title5) .padding(.none) .margin(0)
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // description
                Group {
                    let unapproved = String(localized: "This expertise tag is not approved yet.",
                               table: "PhotoClubHubHTML.Ignite",
                               comment: "Shown for Expertises that are temporary.")
                    Span(
                        String(expertise.selectedLocalizedExpertise(isoCode: languageID).localizedExpertise?.usage
                               ?? unapproved)
                    )
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // id
                Group {
                    Span(
                        String(expertise.id)
                    )
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

        }

    }

    private func lastPathComponent(fullUrl: String) -> String {
        let url = URL(string: fullUrl)
        let lastComponent: String = url?.lastPathComponent ?? "error in lastPathComponent"
        return "/images/\(lastComponent)"
    }

    private func describe(roles: [MemberRole: Bool?]) -> String {
        for role in roles {
            for definedRole in MemberRole.allCases {
                if role.key==definedRole && role.value==true {
                    return definedRole.displayNameForAppUI.capitalized // was table: "PhotoClubHubHTML.Ignite"
                }
            }
        }
        return ""
    }

}
