//
//  MemberPortfolio+roles.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 20/10/2023.
//

extension MemberPortfolio { // computed properties related to roles of members in their club

    var roleDescription: String {
        var prefixList = [String]()
        var suffixList = [String]()
        var result: String = ""
        let andLocalized = String(localized: "and", table: "Package",
                                  comment: "To generate strings like \"secretary and admin\"")

        if photographer.isDeceased {
            prefixList.append(MemberStatus.deceased.localizedString())
        }
        if isFormerMember && !isHonoraryMember { prefixList.append(MemberStatus.former.localizedString()) }

        if isChairman { suffixList.append(MemberRole.chairman.localizedString()) }
        if isViceChairman { suffixList.append(MemberRole.viceChairman.localizedString()) }
        if isTreasurer { suffixList.append(MemberRole.treasurer.localizedString()) }
        if isSecretary { suffixList.append(MemberRole.secretary.localizedString()) }
        if isAdmin { suffixList.append(MemberRole.admin.localizedString()) }
        if isOther { suffixList.append(MemberRole.other.localizedString()) }

        if isProspectiveMember { suffixList.append(MemberStatus.prospective.localizedString()) } else {
            if isHonoraryMember { suffixList.append(MemberStatus.honorary.localizedString()) } else {
                if isMentor { suffixList.append(MemberStatus.coach.localizedString()) } else {
                    suffixList.append(MemberStatus.current.localizedString())
                }
            }
        }

        for prefix in prefixList {
            result.append(prefix + " ")
        }

        for (index, element) in suffixList.enumerated() {
            result.append(element + " ") // example "secretary "
            if index < suffixList.count-1 {
                result.append(andLocalized + " ") // example "secretary and " unless there are no elements left
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines).capitalizingFirstLetter()
    }

    var roleDescriptionOfClubTown: String {
        let of2 = String(localized: "of2", table: "Package", comment: "<person> of <photo club>")
        return "\(roleDescription) \(of2) \(self.organization.fullNameTown)"
    }

    public var memberRolesAndStatus: MemberRolesAndStatus {
        get { // conversion from Bool to dictionary
            var memberRS = MemberRolesAndStatus(roles: [:], status: [:])

            if photographer.isDeceased { memberRS.status[.deceased] = true }
            if isFormerMember { memberRS.status[.former] = true }
            if isHonoraryMember { memberRS.status[.honorary] = true}
            if isProspectiveMember { memberRS.status[.prospective] = true }
            if isMentor { memberRS.status[.coach] = true }
            if !isFormerMember && !isHonoraryMember && !isProspectiveMember && !isMentor {
                memberRS.status[.current] = true
            }

            if isChairman { memberRS.roles[.chairman] = true }
            if isViceChairman { memberRS.roles[.viceChairman] = true }
            if isTreasurer { memberRS.roles[.treasurer] = true }
            if isSecretary { memberRS.roles[.secretary] = true }
            if isAdmin { memberRS.roles[.admin] = true }
            if isOther { memberRS.roles[.other] = true }

            return memberRS
        }
        set { // merge newValue with existing dictionary
            if let newBool = newValue.status[.deceased] {
                photographer.isDeceased = newBool!
            }
            if let newBool = newValue.status[.former] {
                isFormerMember = newBool!
            }
            if let newBool = newValue.status[.honorary] {
                isHonoraryMember = newBool!
            }
            if let newBool = newValue.status[.prospective] {
                isProspectiveMember = newBool!
            }
            if let newBool = newValue.status[.coach] {
                isMentor = newBool!
            }
            if let newBool = newValue.roles[.chairman] {
                isChairman = newBool!
            }
            if let newBool = newValue.roles[.viceChairman] {
                isViceChairman = newBool!
            }
            if let newBool = newValue.roles[.treasurer] {
                isTreasurer = newBool!
            }
            if let newBool = newValue.roles[.secretary] {
                isSecretary = newBool!
            }
            if let newBool = newValue.roles[.admin] {
                isAdmin = newBool!
            }
            if let newBool = newValue.roles[.other] {
                isOther = newBool!
            }
        }
    }

}
