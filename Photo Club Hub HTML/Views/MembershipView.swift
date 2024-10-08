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

    static let allPredicate = NSPredicate(format: "TRUEPREDICATE")
    private var specificClubPredicate = allPredicate // temporary value, gets overwritten within init()
    static private var club = Organization() // temporary value overwritten by explicit init()

    init(club: Organization) {
        MembershipView.club = club
        self.specificClubPredicate = NSPredicate(format: "self = %@",
                                                 argumentArray: [club])
    }

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)],
        predicate: allPredicate, /* NSPredicate(format: ".organization_ = %@",
                               argumentArray: [club]), */
        animation: .default)
    private var singleClubsMembers: FetchedResults<MemberPortfolio>

    var body: some View {
        Text(MembershipView.club.fullName)
            .font(.headline)
    }
}

#Preview {
    MembershipView(club: ContentView.addFGdeGender())
}
