//
//  ClubListSidebarView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 20/03/2026.
//

import SwiftUI // for View
import Photo_Club_Hub_Data // for OranizationID

struct ClubListSidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var preferences: PreferencesStructHTML
    @Binding var selectedClubIds: Set<OrganizationID>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Organization.fullName_, ascending: true)],
        predicate: ClubListView.clubOnlyPredicate, // reuse static from parent if desired
        animation: .default)
    private var allClubs: FetchedResults<Organization>

    var body: some View {
        List(allClubs, selection: $selectedClubIds) { club in
            NavigationLink { MembershipView(club: club, preferences: $preferences) } label: {
                if club.members.isEmpty {
                    Text(club.fullName)
                        .foregroundStyle(.gray)
                        .font(.title2)
                } else {
                    Text("\(club.fullName) (\(club.members.count))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.link)
                }
            }
        }
    }
}

#Preview("Club Sidebar") { // doesn't work, would need to check detailed logging
    // Provide preview state for bindings
    @Previewable @State var preferences = PreferencesStructHTML.defaultValue

    @Previewable @State var selectedClubIds: Set<OrganizationID> = [ ]

    // Use the preview Core Data context if available in your project
    let context = PersistenceController.preview.container.viewContext

    let waalreIdPlus = OrganizationIdPlus(fullName: "Fotogroep Waalre",
                                          town: "Waalre",
                                          nickname: "fgWaalre")
    let dummy1 = Organization.findCreateUpdate(context: context,
                                               organizationTypeEnum: OrganizationTypeEnum.club,
                                               idPlus: waalreIdPlus)

    let fcVeghelIdPlus = OrganizationIdPlus(fullName: "Fotoclub Veghel",
                                            town: "Veghel",
                                            nickname: "fcVeghel")
    let dummy2 = Organization.findCreateUpdate(context: context,
                                               organizationTypeEnum: OrganizationTypeEnum.club,
                                               idPlus: fcVeghelIdPlus)

    ClubListSidebarView(preferences: $preferences, selectedClubIds: $selectedClubIds)
        .environment(\.managedObjectContext, context)
        .frame(width: 360)
        .onAppear {
            selectedClubIds.insert(dummy1.id)
            selectedClubIds.insert(dummy2.id)
        }
}
