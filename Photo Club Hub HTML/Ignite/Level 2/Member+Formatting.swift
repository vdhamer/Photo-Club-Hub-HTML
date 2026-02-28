//
//  Member+Formatting.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 27/02/2026.
//

import Foundation // for Date
import Photo_Club_Hub_Data // for FotobondMemberNumber
import Ignite // for Span { }

extension Members {

    mutating func formatMembershipYears(start: Date?, end: Date?,
                                        isFormer: Bool,
                                        fotobondMemberNumber: FotobondMemberNumber?) -> Span {
        var years = TimeInterval(0)

        if start != nil {
            let end: Date = (end != nil) ? end! : Date.now // optional -> not optional
            let start: Date = ((start != nil) && (start! < Date.distantFuture)) ? start! : Date.now // if "9999-01-01"
            let dateInterval = DateInterval(start: start, end: end)
            years = dateInterval.duration / (365.25 * 24 * 60 * 60)
        }

        let fotobondString: String
        if showFotobondMemberNumber, let fotobondMemberNumber {
            fotobondString = " Fotobond #\(String(fotobondMemberNumber.display))" // display 301046 as "0301046"
        } else {
            fotobondString = ""
        }

        let unknown = Span(String(localized: "-",
                                  table: "PhotoClubHubHTML.Ignite",
                                  comment: "Shown in member table when start date unavailable"))

        if isFormer == false { // if current member, displays "Member for NN.N years"
            guard start != nil else { return unknown }

            currentMembersTotalYears += years
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let formattedStartDate = dateFormatter.string(from: start!)
            return Span(String(localized: "Member for past \(formatYears(years)) years",
                               table: "PhotoClubHubHTML.Ignite",
                               comment: "Membership duration for current members"))
            .hint(text: String(localized:
                               """
                               From \(formattedStartDate) \(fotobondString)
                               """,
                               table: "PhotoClubHubHTML.Ignite",
                               comment: "Mouseover hint on cell containing start-end years"))
        } else { // if current member, displays "Member from YYYYY to YYYY"
            formerMembersTotalYears += years
            guard end != nil && start != nil else { return unknown }
            return Span(String(localized: "Member from \(toYear(date: start!)) to \(toYear(date: end!))",
                               table: "PhotoClubHubHTML.Ignite",
                               comment: "Membership duration for current members"))
            .hint(text: String(localized:
                               """
                               From \(toYear(date: start!)) to \(toYear(date: end!)) (\(formatYears(years)) years)\
                               \(fotobondString)
                               """,
                               table: "PhotoClubHubHTML.Ignite",
                               comment: "Mouseover hint on cell containing start-end years"))
        }
    }

    func formatYears(_ years: Double) -> String {
        String(format: "%.1f", locale: Locale(identifier: "nl_NL"), years) // "1,2"
    }

    private func toYear(date: Date) -> String {
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: date) // "2020"
    }

    func fullName(givenName: String,
                  infixName: String = "",
                  familyName: String) -> String {
        if infixName.isEmpty {
            return givenName + " " + familyName
        } else {
            return givenName + " " + infixName + " " + familyName
        }
    }

}
