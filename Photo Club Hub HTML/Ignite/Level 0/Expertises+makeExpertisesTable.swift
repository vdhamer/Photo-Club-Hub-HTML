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
                                      pageLanguageID: String,
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
                    return lhs.selectedLocalizedExpertise(isoCode: pageLanguageID).name <
                           rhs.selectedLocalizedExpertise(isoCode: pageLanguageID).name
                }
            }

            return MakeExpertisesTableResult(
                table: Table {
                    for expertise in expertises {
                        makeExpertiseRow(moc: moc, expertise: expertise, pageLanguageID: pageLanguageID)
                    }
                }
                header: {
                    String(localized: "Expertise",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(pageLanguageID),
                           comment: "HTML table header for expertise name column.")
                    String(localized: "Description",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(pageLanguageID),
                           comment: "HTML table header for the description column.")
                    String(localized: "Idenfifier",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(pageLanguageID),
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
                                           pageLanguageID: String) -> Row {

        return Row {

            Column { // localized name
                let url: String =
                    "/\(ExpertisesPage.relativePath(languageID: pageLanguageID, expertiseID: expertise.id))/"
                let count: Int = PhotographerExpertise.count(context: moc, expertiseID: expertise.id)
                let nonBreakingSpace: String = "\u{202F}" // Unicode non-breaking (narrow width) space
                let multiplicationX = "×" // a typography thing
                Group {
                    Text {
                        Link(String(expertise.isSupported ?
                                    "\(expertise.selectedLocalizedExpertise(isoCode: pageLanguageID).name)" :
                                    String(expertise.id))
                             + String(" (\(count)\(nonBreakingSpace)\(multiplicationX))"),
                             target: url
                        )
                        .linkStyle(.hover)
                    } .font(.title5) .padding(.none) .margin(0)
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // description
                Group {
                    let noDescription = String(localized: "This expertise has no description yet.",
                               table: "PhotoClubHubHTML.Ignite",
                               bundle: Bundle.forLanguage(pageLanguageID), // the page's language, not the Mac's
                               comment: "Shown in the description column for an expertise that has no usage text.")
                    Span(
                        String(expertise.selectedLocalizedExpertise(isoCode: pageLanguageID).localizedExpertise?.usage
                               ?? noDescription)
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

}
