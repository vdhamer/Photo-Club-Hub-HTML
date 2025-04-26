//
//  LocalizedKeywordResult.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 26/04/2025.
//

import Foundation

struct LocalizedKeywordResult {
    let localizedKeyword: LocalizedKeyword? // a given keyword doesn't have a translation if it isn't defined at Level 0
    let id: String // fallback if localizedKeyword is nil
}

extension LocalizedKeywordResult: Comparable {

    static func < (lhs: LocalizedKeywordResult, rhs: LocalizedKeywordResult) -> Bool {
        guard lhs.localizedKeyword != nil else { return false } // put untranslateable at end of list
        guard rhs.localizedKeyword != nil else { return true } // put untranslateable at end of list
        guard lhs.localizedKeyword!.name != nil else {return Bool.random()} // to protect < function. Shouldn't happen.
        guard rhs.localizedKeyword!.name != nil else {return Bool.random()} // to protect < function. Shouldn't happen.
        return lhs.localizedKeyword!.name! < rhs.localizedKeyword!.name! // normal sorting
    }

}
