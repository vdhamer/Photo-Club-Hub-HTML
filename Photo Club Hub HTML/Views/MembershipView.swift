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

    @FetchRequest var fetchRequestClubMembers: FetchedResults<MemberPortfolio> // filled during init()
    let club: Organization

    init(club: Organization) {
        self.club = club
        let sortDescriptor1 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)
        let sortDescriptor2 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.givenName_, ascending: true)
        let predicate = NSPredicate(format: "organization_ = %@", argumentArray: [club])
        // https://www.youtube.com/watch?v=O4043RVjCGU HackingWithSwift session on dynamic Core Data fetch requests:
        _fetchRequestClubMembers = FetchRequest<MemberPortfolio>(sortDescriptors: [sortDescriptor1, sortDescriptor2],
                                                                 predicate: predicate,
                                                                 animation: .bouncy(duration: 1))
    }

    var body: some View {
        List {
            if fetchRequestClubMembers.isEmpty {
                Text("Please select a club with members.")
            } else {
                ForEach(fetchRequestClubMembers, id: \.self) { member in
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
        if let content, content.isEmpty==false {
            return content + " "
        }
        return ""
    }
}

 #Preview {
     @Previewable @Environment(\.managedObjectContext) var viewContext
     let fgDeGender = Organization.addHardcodedFgDeGender(context: viewContext)
     MembershipView(club: fgDeGender)
 }
