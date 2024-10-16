//
//  MembershipView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/10/2024.
//

import SwiftUI
import CoreData

struct MembershipView: View {
    @Environment(\.managedObjectContext) private var viewContext

    private var specificClubPredicate = NSPredicate(format: "TRUEPREDICATE") // value gets overwritten within init()
    @State var club: Organization? // Optional to avoid having to assign it a value using designated initializer

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)],
//        predicate: NSPredicate(format: "TRUEPREDICATE"),
//        predicate: NSPredicate(format: "FALSEPREDICATE"),
//        predicate: NSPredicate(format: "organization_ = %@",
//                               argumentArray: [club]), // cannot access club in property initializer
        predicate: NSPredicate(format: "fotobondNumber = %@",
                               argumentArray: [1620103]),
//        predicate: specificClubPredicate  // cannot access spedificClubPredicate in property initializer
        animation: .default)
    var clubMembers: FetchedResults<MemberPortfolio>

    init(club: Organization) {
        self.club = club
    }

    var body: some View {
        List {
            if clubMembers.isEmpty {
                Text("There are no known members for \(club?.fullName ?? "club <nil>").")
            } else {
                ForEach(clubMembers, id: \.self) { member in
                    Text("""
                         \(member.photographer_?.givenName_ ?? "given name?") \
                         \(infix(content: member.photographer_?.infixName))\
                         \(member.photographer_?.familyName_ ?? "family name?") \
                         (\(member.organization_?.fullName ?? "club name?"))
                         """)
                }
            }
        }
    }

    private func infix(content: String?) -> String {
        if let content {
            return content + " "
        }
        return ""
    }
}

// #Preview { // TODO
//    MembershipView(club: ContentView.addFGdeGender)
// }
