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

private struct MakeClubsTableResult {
    let table: Table
    let memberCount: Int
    let memberCountWithStartDate: Int
}

extension Clubs {

    // former: whether to list former members or current members
    // moc: use this CoreData Managed Object Context
    // club: for which club are we doing this?
    // return Int: count of returned members (can't directly count size of Ignite Table)
    // return Table: Ignite table containing rendering of requested members
    mutating func makeClubsTable(former: Bool,
                                 moc: NSManagedObjectContext,
                                 club: Organization) -> MakeMembersTableResult {
        do {
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
                                  fotobond: Int(member.fotobondNumber),
                                  roles: member.memberRolesAndStatus,
                                  portfolio: member.level3URL_,
                                  thumbnail: member.featuredImageThumbnail
                        )
                    }
                }
                header: {
                    String(localized: "Name",
                           table: "HTML", comment: "HTML table header for member's name column.")
                    String(localized: "Expertise tags",
                           table: "HTML", comment: "HTML table header for member's keywords.")
                    String(localized: "Own website",
                           table: "HTML", comment: "HTML table header for member's own website column.")
                    String(localized: "Portfolio",
                           table: "HTML", comment: "HTML table header for image linked to member's portfolio.")
                },
                memberCount: memberPortfolios.count,
                memberCountWithStartDate: memberPortfolios.filter { $0.membershipStartDate != nil }.count
            )
        } catch {
            fatalError("Failed to fetch memberPortfolios: \(error)")
        }

    }

    // generates an Ignite Row in an Ignite table
    // swiftlint:disable:next function_body_length
    fileprivate mutating func makeMemberRow(moc: NSManagedObjectContext,
                                            photographer: Photographer,
                                            membershipStartDate: Date?, // nil means app didn't receive a start date
                                            membershipEndDate: Date? = nil, // nil means photographer is still a member
                                            fotobond: Int? = nil,
                                            roles: MemberRolesAndStatus = MemberRolesAndStatus(roles: [:], status: [:]),
                                            portfolio: URL? = nil,
                                            thumbnail: URL) -> Row {

        downloadThumbnailToLocal(downloadURL: thumbnail)

        return Row {

            Column { // member's name with any role & status badges
                Group {
                    Text {
                        Link(
                            fullName(givenName: photographer.givenName,
                                     infixName: photographer.infixName,
                                     familyName: photographer.familyName),
                            target: portfolio ??
                                    URL(string: MemberPortfolio.emptyPortfolioURL) ??
                                    URL(string: "https://www.google.com")! // in case emptoPortfolioURL const is broken
                        )
                            .linkStyle(.hover)
                        if photographer.isDeceased {
                            Badge("Overleden")
                                .badgeStyle(.default)
                                .role(.secondary)
                                .margin(.leading, 10)
                        } else {
                            Badge(describe(roles: roles.roles))
                                .badgeStyle(.subtleBordered)
                                .role(.success)
                                .margin(.leading, 10)
                        }
                    } .font(.title5) .padding(.none) .margin(0)
                    Text {
                        formatMembershipYears(start: membershipStartDate,
                                              end: membershipEndDate,
                                              isFormer: isFormerMember(roles: roles),
                                              fotobond: fotobond)
                    } .font(.body) .padding(.none) .margin(0) .foregroundStyle(.gray)
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column(items: listPhotographerExpertises)
                .verticalAlignment(.middle)

            if photographer.photographerWebsite == nil { // photographer's optional own website
                Column { }
            } else {
                Column {
                    Span(
                        Link( String(localized: "Web site",
                                     table: "HTML", comment: "Clickable link to photographer's web site"),
                              target: photographer.photographerWebsite!.absoluteString)
                            .linkStyle(.hover)
                    )
                    .hint(text: photographer.photographerWebsite!.absoluteString)
                } .verticalAlignment(.middle)
            }

            Column { // clickable thumbnail of recent work
                Image(lastPathComponent(fullUrl: thumbnail.absoluteString), // Ignite prepends /images/
                      description: "clickable link to portfolio")
                    .resizable()
                    .cornerRadius(8)
                    .aspectRatio(.square, contentMode: .fill)
                    .frame(width: 80)
                    .style("cursor: pointer")
                    .onClick {
                        let safeportfolio = portfolio ??
                                            URL(string: MemberPortfolio.emptyPortfolioURL) ??
                                            URL(string: "https://www.google.com")!
                        CustomAction("window.location.href=\"\(safeportfolio)\";")
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

        func listPhotographerExpertises() -> [PageElement] { // defined inside makeMemberRow to access photographer
            var pageElements = [PageElement]()

            let localizedExpertiseResultsLists = LocalizedExpertiseResultLists(moc: moc,
                                                                               photographer.photographerExpertises)

            let standard = generatePageElements(localizedExpertiseResultLists: localizedExpertiseResultsLists,
                                                isStandard: true)
            if let standard { pageElements.append(standard) }

            let nonstandard = generatePageElements(localizedExpertiseResultLists: localizedExpertiseResultsLists,
                                                   isStandard: false)
            if let nonstandard { pageElements.append(nonstandard) }

            return pageElements
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

    fileprivate func downloadThumbnailToLocal(downloadURL: URL) { // for now this is synchronous

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
                fatalError("Error creating URL for /images/\(lastComponent)")
            }
            try jpegData.write(to: localUrl)
            print("Wrote jpg to \(localUrl)")
        } catch {
            fatalError("Problem in downloadThumbNailToLocal(): \(error)")
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
