//
//  OrganizationsPage+makeOrgTable.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 15/02/2025.
//

import Foundation // for Locale and String.compare(_:locale:)
import Ignite // for Table
import CoreData // for NSSortDescriptor
import Photo_Club_Hub_Data // for Organization

struct MakeClubsTableResult {
    let table: Table // Table is an Ignite Table
    let organizationsCount: Int // count of clubs or museums
}

extension OrganizationsPage {

    // swiftlint:disable function_body_length

    /// Builds organizations tables from the records in Core Data.
    ///
    /// Fetches `Organization` entities matching `organizationType`, sorted by town and name,
    /// and returns an Ignite `Table` plus the number of organizations found.
    ///
    /// For museums: Country and Town columns show geocoded localized names using the `LocalizedAddress` table.
    /// Rows are sorted in-memory by localized Country → Town → Name using the page's locale.
    ///
    /// Members and Fotobond# columns are irrelevant and thus suppressed for Museums.
    /// The distinction between current and former Members is also irrelevant for Museums
    /// (because there are no members).
    ///
    /// - Parameters:
    ///   - moc: The Core Data managed object context used for fetching.
    ///   - languageID: ISO 639-1 language code used for localization and internal link paths.
    /// - Returns: `MakeClubsTableResult` containing the rendered table and number of found Organizations.
    mutating func makeOrgTable(moc: NSManagedObjectContext,
                               organizationType: OrganizationTypeEnum,
                               languageID: String) -> MakeClubsTableResult {
        do {
            let fetchRequest: NSFetchRequest<Organization> = Organization.fetchRequest()

            // All organization types: unsorted fetch -> sorted in-memory below by localCountry → localTown → Name

            fetchRequest.predicate = NSPredicate(format: "organizationType_.organizationTypeName_ = %@",
                                                 argumentArray: [organizationType.rawValue])
            var organizations: [Organization] = try moc.fetch(fetchRequest)

            // Fetch Language entity for this page (used for LocalizedAddress lookup and sorting)
            let langRequest: NSFetchRequest<Photo_Club_Hub_Data.Language> =
                Photo_Club_Hub_Data.Language.fetchRequest()
            langRequest.predicate = NSPredicate(format: "isoCode_ = %@", languageID.lowercased())
            let language: Photo_Club_Hub_Data.Language? = (try? moc.fetch(langRequest))?.first

            // Sort in-memory by localized Country → Town → Name using the page's locale.
            // Organizations without a LocalizedAddress (empty-string fallback) sort to the top.
            if let language {
                let locale = Locale(identifier: languageID)
                organizations.sort { lhs, rhs in
                    let addrLhs = lhs.localizedAddress(for: language)
                    let addrRhs = rhs.localizedAddress(for: language)

                    let countryLhs = addrLhs?.localizedCountry_ ?? ""
                    let countryRhs = addrRhs?.localizedCountry_ ?? ""
                    let countryOrder = countryLhs.compare(countryRhs, locale: locale)
                    if countryOrder != .orderedSame { // decided based on localized Country string
                        return countryOrder == .orderedAscending
                    }

                    let townLhs = addrLhs?.localizedTown_ ?? ""
                    let townRhs = addrRhs?.localizedTown_ ?? ""
                    let townOrder = townLhs.compare(townRhs, locale: locale)
                    if townOrder != .orderedSame { // decided based on localized Town string
                        return townOrder == .orderedAscending
                    }

                    return lhs.fullName.compare(rhs.fullName, locale: locale) == .orderedAscending
                }
            }

            return MakeClubsTableResult(
                table: Table {
                    for org in organizations {
                        makeClubRow(moc: moc, club: org, language: language, languageID: languageID)
                    }
                }
                header: {
                    String(localized: "Country",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for country column.")
                    String(localized: "Town",
                           table: "PhotoClubHubHTML.Ignite",
                           bundle: Bundle.forLanguage(languageID),
                           comment: "HTML table header for town column.")
                    if organizationType == .museum {
                        String(localized: "Museum name",
                               table: "PhotoClubHubHTML.Ignite",
                               bundle: Bundle.forLanguage(languageID),
                               comment: "HTML table header for museum name column.")
                    } else {
                        String(localized: "Club name",
                               table: "PhotoClubHubHTML.Ignite",
                               bundle: Bundle.forLanguage(languageID),
                               comment: "HTML table header for club name column.")
                    }
                    if organizationType == .club {
                        String(localized: "Members",
                               table: "PhotoClubHubHTML.Ignite",
                               bundle: Bundle.forLanguage(languageID),
                               comment: "HTML table header for member count column.")
                    }
                    if organizationType == .museum {
                        String(localized: "Museum website",
                               table: "PhotoClubHubHTML.Ignite",
                               bundle: Bundle.forLanguage(languageID),
                               comment: "HTML table header for museum website link.")
                    } else {
                        String(localized: "Club website",
                               table: "PhotoClubHubHTML.Ignite",
                               bundle: Bundle.forLanguage(languageID),
                               comment: "HTML table header for clubs website link.")
                    }
                    if organizationType == .club {
                        String(localized: "Fotobond #",
                               table: "PhotoClubHubHTML.Ignite",
                               bundle: Bundle.forLanguage(languageID),
                               comment: "HTML table header for club's identifier in Fotobond.")
                    }
                    if organizationType == .club {
                        String(localized: "JSON",
                               table: "PhotoClubHubHTML.Ignite",
                               bundle: Bundle.forLanguage(languageID),
                               comment: "HTML table header for link to JSON input file.")
                    }
                },
                organizationsCount: organizations.count
            )
        } catch {
            fatalError("Failed to fetch organizations: \(error)")
        }

    }
    // swiftlint:enable function_body_length

    // generates single Ignite Row in an Ignite table
    // swiftlint:disable:next function_body_length
    private mutating func makeClubRow(moc: NSManagedObjectContext,
                                      club: Organization,
                                      language: Photo_Club_Hub_Data.Language?,
                                      languageID: String) -> Row {

        return Row { // Ignite Row

            Column { // country
                // Compute displayCountry outside the Group{} builder to satisfy the result builder
                let displayCountry: String = {
                    guard let language, let addr = club.localizedAddress(for: language)
                    else { return "" }
                    return addr.localizedCountry_ ?? ""
                }()
                Group {
                    Span(displayCountry)
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // town
                // Compute displayTown outside the Group{} builder to satisfy the result builder
                let displayTown: String = {
                    guard organizationType == .museum,
                          let language,
                          let addr = club.localizedAddress(for: language)
                    else { return String("\(club.town)".replacingUTF8Diacritics) }
                    return addr.localizedTown_ ?? String("\(club.town)".replacingUTF8Diacritics)
                }()
                Group {
                    Span(displayTown)
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column { // club/museum name
                let membershipListPath: String? = (organizationType == .club && !club.members.isEmpty) ?
                    Members.relativePath(languageID: languageID, clubNickname: club.nickName) : nil
                Group {
                    if let membershipListPath {
                        Text {
                            Link(String(club.fullName.replacingUTF8Diacritics),
                                 target: "/\(membershipListPath)"
                            )
                            .linkStyle(.hover)
                        } .font(.title5) .padding(.none) .margin(0)
                    } else {
                        club.fullName.replacingUTF8Diacritics
                    }
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            if organizationType == .club {
                Column { // member count for this club
                    let membershipListPath = Members.relativePath(languageID: languageID, clubNickname: club.nickName)
                    if !club.members.isEmpty {
                        Span(
                            Link(String("\(club.members.filter { !$0.isFormerMember }.count)"),
                                 target: "/\(membershipListPath)")
                                .linkStyle(.hover)
                        )
                    }
                } .verticalAlignment(.middle)
            }

            Column { // website
                if club.organizationWebsite != nil {
                    Text {
                        Link(String(localized: "🌐",
                                    table: "PhotoClubHubHTML.Ignite",
                                    comment: "Unicode globe symbol in cells in club website column"),
                             target: club.organizationWebsite!)
                        .linkStyle(.hover)
                    } .font(.title5) .padding(.none) .margin(0)
                }
            } .verticalAlignment(.middle)

            if organizationType == .club {
                Column { // Fotobond
                    if let fotobondClubNumber = club.fotobondClubNumber {
                        String(fotobondClubNumber.display) // Int16 301 is displayed as 0301, nil is displayed as "-"
                    } else {
                        String("-")
                    }
                }
                    .verticalAlignment(.middle)
                    .margin(.leading, 10)
            }

            if organizationType == .club {
                Column { // JSON
                    if !club.members.isEmpty {
                        let url: String =
                            "https://github.com/vdhamer/Photo-Club-Hub/blob/main/JSON/\(club.nickName).level2.json"
                        Link(String("json"), target: url)
                    }
                } .verticalAlignment(.middle)
            }

        }

    }

}
