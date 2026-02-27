//
//  Members+makeTable.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 15/02/2025.
//

import Ignite // for Table
import CoreData // for NSSortDescriptor
import Photo_Club_Hub_Data // for Organization

struct MakeMembersTableResult {
    let table: Table
    let memberCount: Int
    let memberCountWithStartDate: Int
}

let maxKeywordsPerMember: Int = 2

extension Members {

    // Builds and returns an Ignite HTML table of members (current or former) for a specific organization,
    // along with a few counts.
    //
    // input:
    //   - former: whether to list former members or current members
    //   - moc: use this CoreData Managed Object Context
    //   - club: Organization whose members are being displayed.
    //
    // returns a struct containing
    //   - table: Ignite table containing HTML rendering of requested members
    //   - memberCount: number of members returned in table
    //   - memberCountWithStartDate: number of returned members who have a non-nil membership start date
    mutating func makeMembersTable(former: Bool,
                                   moc: NSManagedObjectContext,
                                   club: Organization) -> MakeMembersTableResult {
        do {

            // Dictionary that maps local thumbnail filenames (in /Assets/images/foobar.jpg)
            // to the full remote path from which it was downloaded.
            // The dictionary ensures that different remote paths all have unique local filenames.
            // The key string is needed to check if a given candidate local filename is already in use.
            // If it is, try another candidate local filename until an unused candidate filename is found.
            // The value string is for checking if a used local filename happens to have the desired full remote path.
            var localNameToRemotePath: [String: String] = [:] // start off with empty dictionary

            // match sort order used in MembershipView to generate MembershipView SwiftUI view
            let sortDescriptor1 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.givenName_,
                                                   ascending: true)
            let sortDescriptor2 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_,
                                                   ascending: true)

            let fetchRequest: NSFetchRequest<MemberPortfolio> = MemberPortfolio.fetchRequest()
            fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]

            fetchRequest.predicate = NSPredicate(format: "organization_ = %@ AND isFormerMember = %@",
                                                 argumentArray: [club, former])
            let memberPortfolios: [MemberPortfolio] = try moc.fetch(fetchRequest)

            return MakeMembersTableResult(
                table: Table {
                    for member in memberPortfolios {
                        makeMemberRow(moc: moc,
                                  photographer: member.photographer,
                                  membershipStartDate: member.membershipStartDate,
                                  membershipEndDate: member.membershipEndDate,
                                  fotobondMemberNumber: member.fotobondMemberNumber,
                                  roles: member.memberRolesAndStatus,
                                  portfolio: member.level3URL_,
                                  thumbnail: member.featuredImageThumbnail,
                                  dictionary: &localNameToRemotePath
                        )
                    }
                }
                header: { // header is a second closure for an Ignite Table, and not an extra param in the return type
                    String(localized: "Name",
                           table: "PhotoClubHubHTML.Ignite", comment: "HTML table header for member's name column.")
                    String(localized: "Expertise tags",
                           table: "PhotoClubHubHTML.Ignite", comment: "HTML table header for member's keywords.")
                    String(localized: "Own website",
                           table: "PhotoClubHubHTML.Ignite",
                           comment: "HTML table header for member's own website column.")
                    String(localized: "Portfolio",
                           table: "PhotoClubHubHTML.Ignite",
                           comment: "HTML table header for image linked to member's portfolio.")
                },
                memberCount: memberPortfolios.count,
                memberCountWithStartDate: memberPortfolios.filter { $0.membershipStartDate != nil }.count
            )
        } catch {
            fatalError("Failed to fetch memberPortfolios: \(error)")
        }

    }

}
