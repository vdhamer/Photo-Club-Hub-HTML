//
//  Member+ExpertiseRendering.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 27/02/2026.
//

import Foundation // for CharacterSet
import Photo_Club_Hub_Data // for LocalizedExpertiseResult

extension Members {

    private func customHint(localizedExpertiseResults: [LocalizedExpertiseResult]) -> String {
        var hint: String = ""

        for localizedExpertiseResult in localizedExpertiseResults {
            if localizedExpertiseResult.localizedExpertise != nil {
                hint.append(getIconString(isSupported: true) + " " +
                            localizedExpertiseResult.localizedExpertise!.name + " ")
            } else {
                hint.append(getIconString(isSupported: true) + " " + localizedExpertiseResult.id + " ")
            }
        }

        return hint.trimmingCharacters(in: CharacterSet(charactersIn: " "))
    }

    private func getIconString(isSupported: Bool) -> String {
        let lerLists = LocalizedExpertiseResultLists(supportedList: [], temporaryList: [])
        return isSupported ? lerLists.supported.icon : lerLists.temporary.icon
    }

}
