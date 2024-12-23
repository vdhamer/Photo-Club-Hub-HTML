//
//  Members.swift
//  Photo Club Hub - Ignite
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Ignite // for StaticPage
import CoreData // for ManagedObjectContext
import SwiftImageReadWrite // for image format conversion
import AppKit // for CGImage

struct Members: StaticPage {
    var title = "Leden"  // needed by the StaticPage protocol?

    fileprivate var currentMembers = Table {} // init to empty table, then fill during init()
    fileprivate var formerMembers = Table {} // same story
    fileprivate var currentMembersTotalYears: Double = 0 // updated in memberRow()
    fileprivate var formerMembersTotalYears: Double = 0 // updated in memberRow()
    fileprivate var currentMembersCount: Int = 0 // updated in makeTable()
    fileprivate var formerMembersCount: Int = 0 // updated in makeTable()

    fileprivate let dateFormatter = DateFormatter()

    fileprivate var moc: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    fileprivate var club: Organization

    // MARK: - init()

    init(moc: NSManagedObjectContext, club: Organization) {
        self.moc = moc
        self.club = club

        currentMembers = makeTable(former: false)
        formerMembers = makeTable(former: true)
    }

    private mutating func makeTable(former: Bool) -> Table {
        do {
            // match sort order used in MembershipView to generate MembershipView SwiftUI view
            let sortDescriptor1 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.givenName_,
                                                   ascending: true)
            let sortDescriptor2 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_,
                                                   ascending: true)
            let headerCurrent = String(localized: "Member (years)",
                                       table: "Site", comment: "HTML table header for years of membership column.")
            let headerFormer = String(localized: "Member (period)",
                                      table: "Site", comment: "HTML table header for years of membership column.")

            let fetchRequest: NSFetchRequest<MemberPortfolio> = MemberPortfolio.fetchRequest()
            fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]

            fetchRequest.predicate = NSPredicate(format: "organization_ = %@ AND isFormerMember = %@",
                                                 argumentArray: [club, former])
            let memberPortfolios: [MemberPortfolio] = try moc.fetch(fetchRequest)

            if former {
                formerMembersCount = memberPortfolios.count
            } else {
                currentMembersCount = memberPortfolios.count
            }

            return Table {
                for member in memberPortfolios {
                    memberRow(givenName: member.photographer.givenName,
                              infixName: member.photographer.infixName,
                              familyName: member.photographer.familyName,
                              membershipStartDate: member.membershipStartDate,
                              membershipEndDate: member.membershipEndDate,
                              fotobond: Int(member.fotobondNumber),
                              isDeceased: member.photographer.isDeceased,
                              roles: member.memberRolesAndStatus,
                              website: member.photographer.photographerWebsite,
                              portfolio: member.level3URL_,
                              thumbnail: member.featuredImageThumbnail ??
                                         URL("http://www.vdhamer.com/2017_GemeentehuisWaalre_5D2_33-Edit.jpg")
                    )
                }
            }
            header: {
                String(localized: "Name",
                       table: "Site", comment: "HTML table header for member's name column.")
                String(former ? headerFormer : headerCurrent)
                String(localized: "Own website",
                       table: "Site", comment: "HTML table header for member's own website column.")
                String(localized: "Portfolio",
                       table: "Site", comment: "HTML table header for image linked to member's portfolio.")
            }
        } catch {
            fatalError("Failed to fetch memberPortfolios: \(error)")
        }

    }

    // MARK: - body()

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

    // generates an Ignite Row in an Ignite table
    // swiftlint:disable:next function_body_length
    fileprivate mutating func memberRow(givenName: String,
                                        infixName: String = "",
                                        familyName: String,
                                        membershipStartDate: Date?, // nil means app didn't receive a start date
                                        membershipEndDate: Date? = nil, // nil means photographer is still a member now
                                        fotobond: Int? = nil,
                                        isDeceased: Bool = false,
                                        roles: MemberRolesAndStatus = MemberRolesAndStatus(role: [:], status: [:]),
                                        website: URL? = nil, // nils are to keep swiftlint happy
                                        portfolio: URL? = nil,
                                        thumbnail: URL) -> Row {

        downloadThumbnailToLocal(downloadURL: thumbnail)

        return Row {

            Column { // member name and badge for role
                Group {
                    Text {
                        Link(
                            fullName(givenName: givenName, infixName: infixName, familyName: familyName),
                            target: portfolio!) // TODO handle ! operator
                            .linkStyle(.hover)
                        if isDeceased {
                            Badge("Overleden")
                                .badgeStyle(.default)
                                .role(.secondary)
                                .margin(.leading, 10)
                        } else {
                            Badge(describe(roles: roles.role))
                                .badgeStyle(.subtleBordered)
                                .role(.success)
                                .margin(.leading, 10)
                        }
                    } .font(.title5)
                } .horizontalAlignment(.leading)
            } .verticalAlignment(.middle)

            Column { // duration of club membership
                formatMembershipYears(start: membershipStartDate,
                                      end: membershipEndDate,
                                      isFormer: isFormerMember(roles: roles),
                                      fotobond: fotobond ?? 1234567) // TODO
            } .verticalAlignment(.middle)

            if website == nil { // photographer's optional own website
                Column { }
            } else {
                Column {
                    Span(
                        Link( String(localized: "Web site",
                                     table: "Site", comment: "Clickable link to photographer's web site"),
                              target: website!.absoluteString)
                            .linkStyle(.hover)
                    )
                    .hint(text: website!.absoluteString)
                } .verticalAlignment(.middle)
            }

            Column { // clickable thumbnail of recent work
                Image(lastPathComponent(fullUrl: portfolio!.absoluteString+"/thumbs/"+thumbnail.lastPathComponent),
                      description: "clickable link to portfolio")
                    .resizable()
                    .cornerRadius(8)
                    .aspectRatio(.square, contentMode: .fill)
                    .frame(width: 80)
                    .style("cursor: pointer")
                    .onClick {
                        CustomAction("window.location.href=\"\(portfolio!)\";") // TODO !
                    }
            } .verticalAlignment(.middle)

        }
    }

//    fileprivate func isFormerMember(roles: MemberRolesAndStatus) -> Bool {
//        let status: [MemberStatus: Bool?] = roles.status
//        let isFormer: Bool? = status[MemberStatus.former] ?? false // handle missing entry for .former
//        return isFormer ?? false // handle isFormer == nil
//    }

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

    fileprivate func formatYears(years: Double) -> String {
        String(format: "%.1f", locale: Locale(identifier: "nl_NL"), years) // "1,2"
    }

    fileprivate mutating func formatMembershipYears(start: Date?, end: Date?,
                                                    isFormer: Bool,
                                                    fotobond: Int) -> Span {
        var years = TimeInterval(0)
        if start != nil {
            let end: Date = (end != nil) ? end! : Date.now // optional -> not optional
            let dateInterval = DateInterval(start: start!, end: end)
            years = dateInterval.duration / (365.25 * 24 * 60 * 60)
        }

        let unknown = Span(String(localized: "-",
                                  table: "Site",
                                  comment: "Shown in member table when start date unavailable"))
        if isFormer == false { // a current member
            guard start != nil else { return unknown }

            currentMembersTotalYears += years
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let formattedStartDate = dateFormatter.string(from: start!)
            return Span(formatYears(years: years))
                .hint(text: String(localized:
                                   """
                                   From \(formattedStartDate). Fotobond #\(fotobond).
                                   """,
                                   table: "Site",
                                   comment: "Mouseover hint on cell containing start-end years"))
        } else { // a former member
            formerMembersTotalYears += years
            guard !(end == nil || start == nil) else { return unknown }
            let startYear = Calendar.current.dateComponents([.year], from: start!).year ?? 2000
            let endYear: Int
            endYear = Calendar.current.dateComponents([.year], from: end!).year ?? 2000
            return Span("\(startYear)-\(endYear)")
                .hint(text: String(localized:
                                   """
                                   From \(startYear) to \(endYear) (\(formatYears(years: years)) years). \
                                   Fotobond #\(fotobond).
                                   """,
                                   table: "Site",
                                   comment: "Mouseover hint on cell containing start-end years"))
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

    fileprivate func downloadThumbnailToLocal(downloadURL: URL) { // TODO make async

        do {
            // swiftlint:disable:next large_tuple
            var results: (data: Data?, urlResponse: URLResponse?, error: (any Error)?)? = (nil, nil, nil)
            results = URLSession.shared.synchronousDataTask(from: downloadURL)
            guard let data = results?.data else {
                fatalError("Problems fetching thumbnail: \(results?.error?.localizedDescription ?? "")")
            }

            let image: CGImage = try CGImage.load(data: data) // SwiftImageReadWrite package
            let jpegData: Data  = try image.representation.jpeg(scale: 1, compression: 0.65, excludeGPSData: true)

            let lastComponent: String = downloadURL.lastPathComponent // e.g. "2023_FotogroepWaalre_001.jpg"
            let buildDirectoryString = NSHomeDirectory() // app's home directory for a sandboxed MacOS app

            guard let localUrl = URL(string: "file:\(buildDirectoryString)/Assets/images/\(lastComponent)") else {
                fatalError("Trouble decoding /images/\(lastComponent)")
            }
            try jpegData.write(to: localUrl)
            print("Wrote jpg to \(localUrl)")
        } catch {
            fatalError("Problem in downloadThumbNailToLocal(): \(error)")
        }

    }

}

func isFormerMember(roles: MemberRolesAndStatus) -> Bool {
    let status: [MemberStatus: Bool?] = roles.status
    let isFormer: Bool? = status[MemberStatus.former] ?? false // handle missing entry for .former
    return isFormer ?? false // handle isFormer == nil
}
