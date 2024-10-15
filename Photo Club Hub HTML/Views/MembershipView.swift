//
//  MembershipView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/10/2024.
//

import SwiftUI
import CoreData

@MainActor
struct MembershipView: View {
    @Environment(\.managedObjectContext) private var viewContext

    private var specificClubPredicate = NSPredicate(format: "TRUEPREDICATE") // value gets overwritten within init()
    @State static var club: Organization! // Optional! to avoid having to assign it using a designated initializer

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)],
//        predicate: NSPredicate(format: "TRUEPREDICATE"),
        predicate: NSPredicate(format: "FALSEPREDICATE"),
//        predicate: NSPredicate(format: "organization_ = %@",
//                               argumentArray: [_club]),
//        predicate: NSPredicate(format: "fotobondNumber = %@",
//                               argumentArray: [12345]),
        animation: .default)
    var clubMembers: FetchedResults<MemberPortfolio>

    init(getClub: () -> Organization) {
        MembershipView.club = getClub()
    }

    var body: some View {
        List {
            if clubMembers.isEmpty {
                Text("There are no known members for \(MembershipView.club.fullName).")
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

#Preview {
    MembershipView(getClub: ContentView.addFGdeGender)
}
