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
    @State static var club = Organization() // temporary value overwritten by explicit init()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)],
        predicate: NSPredicate(format: "TRUEPREDICATE"),
//        predicate: NSPredicate(format: "organization_ = %@",
//                               argumentArray: [_club]),
        animation: .default)
    var clubMembers: FetchedResults<MemberPortfolio>

    init(getClub: () -> Organization) {
        MembershipView.club = getClub()
    }

    var body: some View {
        List {
            if clubMembers.isEmpty {
//                Text("Club \(MembershipView.club.fullNameTown) has no members.") TODO
                Text("Club has no members.")
            } else {
                ForEach(clubMembers, id: \.self) { member in
                    Text("\(member.photographer_?.givenName_ ?? "given name?")")
                }
            }
        }
    }
}

#Preview {
    MembershipView(getClub: ContentView.addFGdeGender)
}
