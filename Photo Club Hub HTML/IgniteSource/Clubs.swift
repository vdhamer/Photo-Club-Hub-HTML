//
//  Clubs.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Ignite // for StaticPage
import CoreData // for ManagedObjectContext
import SwiftImageReadWrite // for image format conversion
import Photo_Club_Hub_Data // for Organization

struct Clubs: StaticPage {
    var title = "Clubs"  // needed by the StaticPage protocol, but how do I localize it?
    let showFotobondNumber: Bool = false // suppresses showing Fotobond number of members

    fileprivate var currentMembers = Table {} // initialite to empty table, then fill during init()
    var currentMembersTotalYears: Double = 0 // updated in memberRow()
    var formerMembersTotalYears: Double = 0 // updated in memberRow()
    fileprivate var currentMembersCount: Int = 0 // updated in makeTable(), Table doesn't support Table.count
    fileprivate var currentMembersCountWithStartDate: Int = 0

    let dateFormatter = DateFormatter()

    fileprivate var moc: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    // code using moc is executed via moc.performAndWait() and ends up running on the main thread (#1)
    fileprivate var club: Organization
    fileprivate var clubFullNameTown: String // duplicates info in club, but String is sendable and Organization isn't

    // MARK: - init()

    init(moc: NSManagedObjectContext, club: Organization) {
        self.moc = moc
        self.club = club
        self.clubFullNameTown = club.fullNameTown

        let makeTableResult = makeClubsTable(moc: moc)
         currentMembers = makeTableResult.table
    }

    // MARK: - body()

    func body(context: PublishingContext) -> [BlockElement] {

        // MARK: - current members

        Text {
            Badge(String(localized: "Photo clubs",
                         table: "HTML", comment: "Title badge at top of Clubs HTML index page"))
                .badgeStyle(.subtleBordered)
                .role(.success)
        }
        .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

        currentMembers // this is an Ignite Table that renders an array of Ignite Rows
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

        if currentMembersTotalYears > 0 && currentMembersCountWithStartDate > 0 {
            Alert {
                Text {String(localized:
                             """
                             Average membership duration for these \(currentMembersCount) club members is \
                             \(formatYears(currentMembersTotalYears/Double(currentMembersCountWithStartDate))) \
                             years.
                             """,
                             table: "HTML",
                             comment: "Table footnote showing average years of membership of all members."
                )} .horizontalAlignment(.center)
            }
            .margin(.top, .small)
        } else {
            Alert {
                Text { "" }
            }
            .margin(.top, .small)
        }

        Divider() // would like it in a darker color

    }

}

// func isFormerMember(roles: MemberRolesAndStatus) -> Bool {
//     let status: [MemberStatus: Bool?] = roles.status
//     let isFormer: Bool? = status[MemberStatus.former] ?? false // handle missing entry for .former
//     return isFormer ?? false // handle isFormer == nil
// }
