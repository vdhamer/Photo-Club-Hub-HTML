//
//  Members+makeTable.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 15/02/2025.
//

import Ignite // for Table
import CoreData // for NSSortDescriptor
import AppKit // for CGImage
import Photo_Club_Hub_Data // for Organization

struct MakeTableResult {
    let table: Table
    let memberCount: Int
    let memberCountWithStartDate: Int
}

let maxKeywordsPerMember: Int = 2

extension Members {

    // former: whether to list former members or current members
    // moc: use this CoreData Managed Object Context
    // club: for which club are we doing this?
    // return Int: count of returned members (can't directly count size of Ignite Table)
    // return Table: Ignite table containing rendering of requested members
    mutating func makeTable(former: Bool,
                            moc: NSManagedObjectContext,
                            club: Organization) -> MakeTableResult {
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

            return MakeTableResult(
                table: Table {
                    for member in memberPortfolios {
                        makeMemberRow(moc: moc,
                                  photographer: member.photographer,
                                  membershipStartDate: member.membershipStartDate,
                                  membershipEndDate: member.membershipEndDate,
                                  fotobond: Int(member.fotobondNumber),
                                  roles: member.memberRolesAndStatus,
                                  portfolio: member.level3URL_,
                                  thumbnail: member.featuredImageThumbnail ??
                                             URL("http://www.vdhamer.com/2017_GemeentehuisWaalre_5D2_33-Edit.jpg")
                        )
                    }
                }
                header: {
                    String(localized: "Name",
                           table: "HTML", comment: "HTML table header for member's name column.")
                    String(localized: "Areas of expertise",
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

        func listPhotographerExpertises() -> [PageElement] { // defined inside makeMemberRow to access photographer
            var returnResult = [PageElement]()

            for localizedKeywordResult: LocalizedKeywordResult
                    in localizeSortAndClip(moc: moc,
                                           photographer.photographerKeywords) {

                let localizedKeywordString: String
                let localizedKeywordHint: String? // usage String is optional for a LocalizedKeyword struct

                if localizedKeywordResult.localizedKeyword != nil {
                    localizedKeywordString = "🏵️ " + localizedKeywordResult.localizedKeyword!.name
                    localizedKeywordHint = localizedKeywordResult.localizedKeyword!.usage // may be nil
                } else { // use keyword.id if the keyword has no translations are available
                    localizedKeywordString = "🪲 " + localizedKeywordResult.id // for an unstandardized expertise
                    if localizedKeywordResult.customHint == nil {
                        localizedKeywordHint = String(localized: "Unofficial expertise. It has no translations yet.",
                                                      table: "HTML",
                                                      comment: "Hint for expertise without localization")
                    } else {
                        localizedKeywordHint = localizedKeywordResult.customHint // special overrule of mouseover
                    }

                }

                if localizedKeywordHint != nil {
                    returnResult.append(Text(localizedKeywordString) // we can show a normal or warning usage hint
                        .padding(.leading, .large)
                        .margin(0)
                        .hint(text: localizedKeywordHint!)
                        .horizontalAlignment(.leading)
                    )
                } else { // omit hint if there is no usage string provided
                   returnResult.append(Text(localizedKeywordString) // we can show a normal or warning usage hint
                        .padding(.none)
                        .margin(0)
                    )
                }
            }

            return returnResult
        }

    }

    fileprivate func localizeSortAndClip(moc: NSManagedObjectContext,
                                         _ photographerkeywords: Set<PhotographerKeyword>) -> [LocalizedKeywordResult] {
        // first translate keywords to appropriate language and make elements non-optional
        var result1 = [LocalizedKeywordResult]()
        for photographerKeyword in photographerkeywords where photographerKeyword.keyword_ != nil {
            result1.append(photographerKeyword.keyword_!.selectedLocalizedKeyword)
        }

        // then dsort based on selected language.  Has some special behavior for keywords without translation
        let result2: [LocalizedKeywordResult] = result1.sorted()
        let maxCount2 = result2.count // for ["keywordA", "keywordB", "keywordC"] maxCount is 3

        // insert delimeters where needed
        var result3 = [LocalizedKeywordResult]() // start with empty list
        var count: Int = 0
        for item in result2 {
            count += 1
            if count < maxCount2 { // turn this into ["keywordA,", "keywordB,", "keywordC"]
                result3.append(item) // accept appending "," to item
            } else {
                result3.append(LocalizedKeywordResult(localizedKeyword: item.localizedKeyword, id: item.id))
            }
        }

        // limit size to 3 displayed keywords
        if result3.count <= maxKeywordsPerMember { return result3 } // no clipping needed
        var result4 = [LocalizedKeywordResult]()
        for index in 1...maxKeywordsPerMember {
            result4.append(result3[index-1]) // copy the (aphabetically) first three LocalizedKeywordResult elements
        }
        let moreKeyword = Keyword.findCreateUpdateStandard(context: moc,
                                                           id: String(localized: "Too many expertises", table: "HTML",
                                                                      comment: "Shown if photographer has >3 keywords"),
                                                           name: [],
                                                           usage: [])
        let moreLocalizedKeyword: LocalizedKeywordResult = moreKeyword.selectedLocalizedKeyword
        result4.append(LocalizedKeywordResult(localizedKeyword: moreLocalizedKeyword.localizedKeyword,
                                              id: moreKeyword.id,
                                              customHint: customHint(localizedKeywordResults: result3)))

        return result4
    }

    fileprivate func customHint(localizedKeywordResults: [LocalizedKeywordResult]) -> String {
        var hint: String = ""

        for localizedKeywordResult in localizedKeywordResults {
            if localizedKeywordResult.localizedKeyword != nil {
                hint.append("🏵️ " + localizedKeywordResult.localizedKeyword!.name + " ")
            } else {
                hint.append("🪲 " + localizedKeywordResult.id + " ")
            }
        }

        return hint.trimmingCharacters(in: CharacterSet(charactersIn: " "))
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
