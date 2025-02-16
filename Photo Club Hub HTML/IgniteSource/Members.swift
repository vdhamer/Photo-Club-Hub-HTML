//
//  Members.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Ignite // for StaticPage
import CoreData // for ManagedObjectContext
import SwiftImageReadWrite // for image format conversion

struct Members: StaticPage {
    var title = "Leden"  // needed by the StaticPage protocol, but how do I localize it?
    let showFormerMembers: Bool = false // suppresses generating and showing table for former members
    let showFotobondNumber: Bool = false // suppresses showing Fotobond number of members

    fileprivate var currentMembers = Table {} // init to empty table, then fill during init()
    fileprivate var formerMembers = Table {} // same story
    var currentMembersTotalYears: Double = 0 // updated in memberRow()
    var formerMembersTotalYears: Double = 0 // updated in memberRow()
    fileprivate var currentMembersCount: Int = 0 // updated in makeTable(), Table doesn't support Table.count
    fileprivate var formerMembersCount: Int = 0 // updated in makeTable(), Table doesn't support Table.count

    let dateFormatter = DateFormatter()

    fileprivate var moc: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    fileprivate var club: Organization

    // MARK: - init()

    init(moc: NSManagedObjectContext, club: Organization) {
        self.moc = moc
        self.club = club

        (currentMembersCount, currentMembers) = makeTable(former: false, moc: moc, club: club)
        if showFormerMembers {
            (formerMembersCount, formerMembers) = makeTable(former: true, moc: moc, club: club)
        }
    }

    // MARK: - body()

    // swiftlint:disable:next function_body_length
    func body(context: PublishingContext) -> [BlockElement] {

        // MARK: - current members

        Text {
            Badge(String(localized: "The \(currentMembersCount) current members",
                         table: "Site", comment: "Number of current members"))
                .badgeStyle(.subtleBordered)
                .role(.success)
        }
        .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

        currentMembers // this is an Ignite Table that renders an array of Ignite Rows
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

        if currentMembersTotalYears > 0 && currentMembersCount > 0 {
            Alert {
                Text {String(localized:
                    """
                    Average membership duration is \
                    \(formatYears(years: currentMembersTotalYears/Double(currentMembersCount))) \
                    years.
                    """,
                    table: "Site", comment: "Table footnote showing average years of membership of all members."
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

        // MARK: - former members

        if showFormerMembers {
            Text {
                Badge(String(localized: "\(formerMembersCount) former members",
                             table: "Site", comment: "Number of former members"))
                .badgeStyle(.subtleBordered)
                .role(.secondary)
            }
            .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

            formerMembers
                .tableStyle(.stripedRows)
                .tableBorder(true)
                .horizontalAlignment(.center)

            if formerMembersTotalYears > 0 && formerMembersCount > 0 {
                Alert {
                    Text { String(localized:
                    """
                    The listed ex-members were members of this club for, on average, \
                    \(formatYears(years: formerMembersTotalYears/Double(formerMembersCount))) \
                    years.
                    """,
                                  table: "Site",
                                  comment: "Footer for former members table")
                    } .horizontalAlignment(.center)
                }
                .margin(.top, .small)
            } else {
                Alert {
                    Text { "" }
                }
                .margin(.top, .small)
            }
        }
    }

}

func isFormerMember(roles: MemberRolesAndStatus) -> Bool {
    let status: [MemberStatus: Bool?] = roles.status
    let isFormer: Bool? = status[MemberStatus.former] ?? false // handle missing entry for .former
    return isFormer ?? false // handle isFormer == nil
}
