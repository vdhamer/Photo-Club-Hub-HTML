//
//  Members+makeMemberRow.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 27/02/2026.
//

import Ignite // for Row and a lot more
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Photographer

extension Members {

    // swiftlint:disable function_body_length

    /// `Members.makeMemberRow` renders a single Ignite `Row` for a club member with:
    /// - The photographer's name (clickable, navigates to the member's portfolio)
    /// - Number of  years photographer was a member of this club (empty if data is unavailable). Shown below the name.
    /// - Role/status badges (empty if data is not available of if member has no special role or status in this club)
    /// - Personal website link (empty if there is no known personal website)
    /// - Clickable thumbnail that navigates to the member's portfolio
    mutating func makeMemberRow(moc: NSManagedObjectContext,
                                photographer: Photographer,
                                membershipStartDate: Date?, // nil means app didn't receive a start date
                                membershipEndDate: Date? = nil, // nil means photographer is still a member
                                fotobondMemberNumber: FotobondMemberNumber? = nil,
                                roles: MemberRolesAndStatus = MemberRolesAndStatus(roles: [:], status: [:]),
                                portfolio: URL? = nil,
                                thumbnail: URL,
                                dictionary: inout [String: String]) -> Row {

        return Row {

            Column { // member's name with any role & status badges
                Group {
                    Text { // Photographer's name and role/status in club
                        Link(
                            fullName(givenName: photographer.givenName,
                                     infixName: photographer.infixName,
                                     familyName: photographer.familyName).replacingUTF8Diacritics,
                            target: portfolio ??
                            URL(string: MemberPortfolio.emptyPortfolioURL) ??
                            URL(string: "https://www.google.com")! // in case emptyPortfolioURL const is broken
                        )
                        .linkStyle(.hover)
                        if roles.status[.deceased] == true {
                            Badge(MemberStatus.deceased.displayName)
                                .badgeStyle(.default)
                                .role(.secondary)
                                .margin(.leading, 10)
                        } else {
                            let rolesAndStatus: MemberRolesAndStatus = roles
                            let statusDict: [MemberStatus: Bool?] = rolesAndStatus.status
                            let memberStatus: MemberStatus? = getMemberStatus(statusDictionary: statusDict)
                            if let memberStatus {
                                Badge(memberStatus.displayName)
                                    .badgeStyle(.subtleBordered)
                                    .role(.success)
                                    .margin(.leading, 10)
                            }
                            let rolesDict: [MemberRole: Bool?] = rolesAndStatus.roles
                            let memberRole: MemberRole? = getMemberRole(roleDictionary: rolesDict)
                            if let memberRole {
                                Badge(memberRole.displayName)
                                    .badgeStyle(.subtleBordered)
                                    .role(.success)
                                    .margin(.leading, 10)
                            }

                        }
                    } .font(.title5) .padding(.none) .margin(0)
                    Text { // show how long the photographer was a member of this club
                        formatMembershipYears(start: membershipStartDate,
                                              end: membershipEndDate,
                                              isFormer: isFormerMember(roles: roles),
                                              fotobondMemberNumber: fotobondMemberNumber)
                    } .font(.body) .padding(.none) .margin(0) .foregroundStyle(.gray)
                } .horizontalAlignment(.leading) .padding(.none) .margin(0)
            } .verticalAlignment(.middle)

            Column(items: listPhotographerExpertises) // expertise tags (can be empty array)
                .verticalAlignment(.middle)

            if photographer.photographerWebsite == nil { // photographer's optional own website
                Column { }
            } else {
                Column {
                    Span(
                        Link( String(localized: "Website",
                                     table: "PhotoClubHubHTML.Ignite",
                                     comment: "Clickable link to photographer's website"),
                              target: photographer.photographerWebsite!.absoluteString)
                        .linkStyle(.hover)
                    )
                    .hint(text: photographer.photographerWebsite!.absoluteString)
                } .verticalAlignment(.middle)
            }

            Column { // clickable thumbnail of recent work
                Image("/images/"+loadThumbnailToLocal(fullUrl: thumbnail, dictionary: &dictionary),
                      description: "clickable link to portfolio") // Ignite prepends /images/
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

        /// Returns the first applicable member status (excluding `.former` and `.current`).
        /// - Parameter statusDictionary: A map of statuses to optional booleans (true means applicable).
        /// - Returns: The first non-default status to display, or `nil` if none apply.
        func getMemberStatus(statusDictionary: [MemberStatus: Bool?]) -> MemberStatus? {
            for (status, applicable) in statusDictionary where applicable == true {
                // don't display .former because it is shown in list containing only formers
                if status != .former && status != .current {
                    return status
                }
            }
            return nil
        }

        /// Returns the first applicable member role.
        /// - Parameter roleDictionary: A map of roles to optional booleans (true means applicable).
        /// - Returns: The first role to display, or `nil` if none apply.
        func getMemberRole(roleDictionary: [MemberRole: Bool?]) -> MemberRole? {
            for (role, applicable) in roleDictionary where applicable == true {
                return role
            }
            return nil
        }

        /// Renders a line of expertise tags as a `PageElement`.
        /// Uses the provided localized expertise lists and the `isSupported` flag to select either the
        /// supported (official) or temporary (nonstandard) list, then builds a text line with the proper icon,
        /// names, delimiters, and optional hint.
        /// - Parameters:
        ///   - localizedExpertiseResultLists: Source of supported and temporary expertise results for the member.
        ///   - isSupported: When `true`, renders the supported list; otherwise renders the temporary list.
        /// - Returns: A `PageElement` containing the expertise line, or `nil` when there’s nothing to display.
        func generatePageElements(localizedExpertiseResultLists: LocalizedExpertiseResultLists, isSupported: Bool)
        -> PageElement? {
            let localizedExpertiseResultList = isSupported ? localizedExpertiseResultLists.supported :
            localizedExpertiseResultLists.temporary
            guard !localizedExpertiseResultList.list.isEmpty else { return nil } // nothing to display

            var hint: String?
            var customHint: String = ""
            var string = localizedExpertiseResultLists.getIconString(isSupported: isSupported) // line starts with icon

            for localizedExpertiseResult in localizedExpertiseResultList.list {
                string.append(" " + localizedExpertiseResult.name
                              + localizedExpertiseResult.delimiterToAppend)
                hint = localizedExpertiseResult.localizedExpertise?.usage
                customHint = localizedExpertiseResult.customHint ?? ""
            }

            if !isSupported {
                if hint == nil && customHint == "" {
                    return Text(string)
                        .horizontalAlignment(.leading)
                        .padding(.none)
                        .margin(5)
                        .hint(text: String(localized: "Unofficial expertise. It has no translations yet.",
                                           table: "PhotoClubHubHTML.Ignite",
                                           comment: "Hint for expertise without localization"))
                } else {
                    return Text(string)
                        .horizontalAlignment(.leading)
                        .padding(.none)
                        .margin(5)
                        .hint(text: String(localized: "Expertises: \(customHint)",
                                           table: "PhotoClubHubHTML.Ignite",
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

        /// Builds the expertise section for the member.
        /// Combines supported and temporary (nonstandard) expertise lists into an array of `PageElement`s,
        /// preserving their respective hints and icons.
        /// - Returns: An array of `PageElement` items to render in the expertise column (which can be empty).
        func listPhotographerExpertises() -> [PageElement] { // defined inside makeMemberRow to access photographer
            var pageElements = [PageElement]()

            let localizedExpertiseResultsLists = LocalizedExpertiseResultLists(moc: moc,
                                                                               photographer.photographerExpertises)

            let standard = generatePageElements(localizedExpertiseResultLists: localizedExpertiseResultsLists,
                                                isSupported: true)
            if let standard { pageElements.append(standard) }

            let nonstandard = generatePageElements(localizedExpertiseResultLists: localizedExpertiseResultsLists,
                                                   isSupported: false)
            if let nonstandard { pageElements.append(nonstandard) }

            return pageElements
        }

    }

    // swiftlint:enable function_body_length

}
