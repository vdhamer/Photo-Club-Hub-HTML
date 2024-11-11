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

// swiftlint:disable:next type_body_length
struct Members: StaticPage {
    var title = "Leden"  // needed by the StaticPage protocol?

    fileprivate var currentMembersTotalYears: Double = 0 // updated in memberRow()
    fileprivate var currentMembersCount: Int = 0 // updated in memberRow(). Can this become a computed property?
    fileprivate var formerMembersTotalYears: Double = 0 // updated in memberRow()
    fileprivate var formerMembersCount: Int = 0 // updated in memberRow(). Can this become a computed property?
    fileprivate let dateFormatter = DateFormatter()
    fileprivate var currentMembers = Table {} // init to empty table, then fill during init()
    fileprivate var formerMembers = Table {} // same story

    fileprivate var moc: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    fileprivate var club: Organization

    // MARK: - init()

    init(moc: NSManagedObjectContext, club: Organization) {
        self.moc = moc
        self.club = club

        let predicate = NSPredicate(format: "organization_ = %@ AND isFormerMember = %@",
                                    argumentArray: [club, false])
        let fetchRequest: NSFetchRequest<MemberPortfolio> = MemberPortfolio.fetchRequest()
        fetchRequest.predicate = predicate
        // match sort order used in MembershipView to generate MembershipView SwiftUI view
        let sortDescriptor1 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.givenName_, ascending: true)
        let sortDescriptor2 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]

        do {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let memberPortfolios: [MemberPortfolio] = try moc.fetch(fetchRequest)
            currentMembers = Table {
                for member in memberPortfolios {
                    memberRow(givenName: member.photographer.givenName,
                              infixName: member.photographer.infixName,
                              familyName: member.photographer.familyName,
                              start: member.membershipStartDate,
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
                String(localized: "Membership",
                       table: "Site", comment: "HTML table header for years of membership column.")
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

        currentMembers // interpret this as an Ignite Table { } that returns [Rows]
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

        if currentMembersCount > 0 {
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
        }

        Divider() // don't know how to get it darker or in color

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

        if formerMembersCount > 0 {
            Alert {
                Text {
                    """
                    De vermeldde ex-leden waren gemiddeld \
                    \(formatYears(years: formerMembersTotalYears/Double(formerMembersCount))) \
                    jaar lid.
                    """
                } .horizontalAlignment(.center)
            }
            .margin(.top, .small)
        }
    }

    func bestuursRol(row: Int) -> String {
        let mod = row % 8
        switch mod {
        case 0: return "Penningmeester"
        case 4: return "Voorzitter"
        default: return ""
        }
    }

    // swiftlint:disable:next function_body_length function_parameter_count
    fileprivate mutating func memberRow(givenName: String,
                                        infixName: String = "",
                                        familyName: String,
                                        start: Date,
                                        end: Date? = nil, // nil means "still a member",
                                        fotobond: Int? = nil,
                                        isDeceased: Bool = false,
                                        roles: MemberRolesAndStatus = MemberRolesAndStatus(role: [:], status: [:]),
                                        website: URL?,
                                        portfolio: URL?,
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
                formatMembershipYears(start: start, end: end, fotobond: fotobond ?? 1234567) // TODO
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
                            .role(.default)
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

    fileprivate mutating func memberRow1(givenName: String, // TODO remove memberRow1()
                                         infixName: String = "",
                                         familyName: String,
                                         start: Date,
                                         end: Date? = nil, // nil means "still a member",
                                         fotobond: Int? = nil,
                                         isDeceased: Bool = false,
                                         role: String = "",
                                         website: String = "",
                                         portfolio: String,
                                         thumbnailSuffix: String) -> Row {
        return Row {
            Column {
                Group {
                    Text {
                        Link(
                            fullName(givenName: givenName, infixName: infixName, familyName: familyName),
                            target: "\(portfolio)")
                        .linkStyle(.hover)
                        if isDeceased {
                            Badge("Overleden")
                                .badgeStyle(.default)
                                .role(.secondary)
                                .margin(.leading, 10)
                        } else {
                            Badge(role)
                                .badgeStyle(.subtleBordered)
                                .role(.success)
                                .margin(.leading, 10)
                        }
                    } .font(.title5)
                } .horizontalAlignment(.leading)
            } .verticalAlignment(.middle)

            Column {
                formatMembershipYears(start: start, end: end, fotobond: fotobond ?? 1234567)
            } .verticalAlignment(.middle)

            if website.isEmpty {
                Column { }
            } else {
                Column {
                    Span(
                        Link( String(localized: "Web site",
                                     table: "Site", comment: "Clickable link to photographer's web site"),
                              target: website)
                            .linkStyle(.hover)
                            .role(.default)
                    )
                    .hint(text: website)
                } .verticalAlignment(.middle)
            }

            Column {
                Image(lastPathComponent(fullUrl: portfolio+"/thumb/"+thumbnailSuffix),
                      description: "clickable link to portfolio")
                    .resizable()
                    .cornerRadius(8)
                    .aspectRatio(.square, contentMode: .fill)
                    .frame(width: 80)
                    .style("cursor: pointer")
                    .onClick {
                        CustomAction("window.location.href=\"\(portfolio)\";")
                    }
            } .verticalAlignment(.middle)

        }
    }

    fileprivate func formatYears(years: Double) -> String {
        String(format: "%.1f", locale: Locale(identifier: "nl_NL"), years) // "1,2"
    }

    fileprivate mutating func formatMembershipYears(start: Date, end: Date?, fotobond: Int) -> Span {
        let endDate: Date = (end != nil) ? end! : Date.now
        let dateInterval = DateInterval(start: start, end: endDate)
        let years = dateInterval.duration / (365.25 * 24 * 60 * 60)
        if end == nil {
            currentMembersTotalYears += years
            currentMembersCount += 1
            let formattedStartDate = dateFormatter.string(from: start)
            return Span(formatYears(years: years))
                .hint(text: "Vanaf \(formattedStartDate). Fotobond #\(fotobond).")
        } else {
            formerMembersTotalYears += years
            formerMembersCount += 1
            let startYear = Calendar.current.dateComponents([.year], from: start).year ?? 2000
            let endYear = Calendar.current.dateComponents([.year], from: end!).year ?? 2000

            return Span("\(startYear)-\(endYear)")
                   .hint(text: "Vanaf \(start) t/m \(end!) (\(formatYears(years: years)) jaar). Fotobond #\(fotobond).")
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

            let lastComponent: String = downloadURL.lastPathComponent
            let buildDirectoryString = NSHomeDirectory() // app's home directory for a sandboxed MacOS app

            guard let localUrl = URL(string: "file:\(buildDirectoryString)/Build/images/\(lastComponent)") else {
                fatalError("Trouble decoding /images/\(lastComponent)")
            }
            try jpegData.write(to: localUrl)
            print("Wrote jpg to \(localUrl)")
        } catch {
            fatalError("Problem in downloadThunNailToLocal(): \(error)")
        }

    }

}
