//
//  Members.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Ignite // for StaticPage
import CoreData // for ManagedObjectContext
import SwiftImageReadWrite // for image format conversion
import Photo_Club_Hub_Data // for Organization

struct Members: StaticPage {
    var title: String {
        String(localized: "Members",
               table: "PhotoClubHubHTML.Ignite",
               bundle: languageBundle,
               comment: "HTML page title (shown in browser tab) for the Members page")
    }
    let showFotobondMemberNumber: Bool = false // suppresses showing Fotobond number of members

    let languageID: String  // ISO 639-1 code, e.g. "nl"
    let clubNickname: String // used to build the page path, e.g. "fgWaalre"
    let languageBundle: Bundle // derived from languageID; internal so extensions in this module can access it

    static func relativePath(languageID: String, clubNickname: String) -> String {
        "\(languageID)/clubs/\(clubNickname)" // should match Photo Club Hub HTML/Documentation/Folders.md
    }
    var path: String { "/\(Self.relativePath(languageID: languageID, clubNickname: clubNickname))" }

    private var currentMembers = Table {} // initialite to empty table, then fill during init()
    private var formerMembers = Table {} // same story
    var currentMembersTotalYears: Double = 0 // updated in memberRow()
    var formerMembersTotalYears: Double = 0 // updated in memberRow()
    private var currentMembersCount: Int = 0 // updated in makeTable(), Table doesn't support Table.count
    private var currentMembersCountWithStartDate: Int = 0
    private var formerMembersCount: Int = 0 // updated in makeTable(), Table doesn't support Table.count
    private var formerMembersCountWithStartDate: Int = 0

    let dateFormatter = DateFormatter()

    private var moc: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    // code using moc is executed via moc.performAndWait() and ends up running on the main thread (#1)
    private var club: Organization
    private var clubFullNameTown: String // duplicates info in club, but String is sendable and Organization isn't

    // MARK: - init()

    init(moc: NSManagedObjectContext, club: Organization, languageID: String, preferences: PreferencesStructHTML) {
        self.moc = moc
        self.club = club
        self.clubFullNameTown = club.fullNameTown
        self.languageID = languageID
        self.clubNickname = club.nickName
        self.languageBundle = Bundle.forLanguage(languageID)

        let makeTableResult = makeMembersTable(former: false, moc: moc, club: club, preferences: preferences)
        currentMembersCount = makeTableResult.memberCount
        currentMembers = makeTableResult.table
        currentMembersCountWithStartDate = makeTableResult.memberCountWithStartDate
        if preferences.showFormerMembers {
            let makeTableResult = makeMembersTable(former: true, moc: moc, club: club, preferences: preferences)
            formerMembersCount = makeTableResult.memberCount
            formerMembersCountWithStartDate = makeTableResult.memberCountWithStartDate
            formerMembers = makeTableResult.table
        }
    }

    // MARK: - body()

    // swiftlint:disable:next function_body_length
    func body(context: PublishingContext) -> [BlockElement] {

        // MARK: - Links

        SiteNavigationBar(languageID: languageID)

        // MARK: - current members

        Text {
            Badge(String(localized: "Current members of \(clubFullNameTown)",
                         table: "PhotoClubHubHTML.Ignite",
                         bundle: languageBundle,
                         comment: "Title badge at top of Members HTML page"))
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
                             table: "PhotoClubHubHTML.Ignite",
                             bundle: languageBundle,
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

        // MARK: - former members

        if formerMembersCount > 0 {
            Text {
                Badge(String(localized: "\(formerMembersCount) former members",
                             table: "PhotoClubHubHTML.Ignite",
                             bundle: languageBundle,
                             comment: "Number of former members"))
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
                                  \(formatYears(formerMembersTotalYears/Double(formerMembersCountWithStartDate))) \
                                  years.
                                  """,
                                  table: "PhotoClubHubHTML.Ignite",
                                  bundle: languageBundle,
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

        FooterText(languageID: languageID)

    }

}

func isFormerMember(roles: MemberRolesAndStatus) -> Bool {
    let status: [MemberStatus: Bool?] = roles.status
    let isFormer: Bool? = status[MemberStatus.former] ?? false // handle missing entry for .former
    return isFormer ?? false // handle isFormer == nil
}
