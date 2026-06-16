//
//  MembershipView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/10/2024.
//

import SwiftUI
import CoreData
import CoreLocation // for CLLocationCoordinate2DMake
import Photo_Club_Hub_Data // for Organization and PersonName

struct MembershipView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest var fetchRequestClubMembers: FetchedResults<MemberPortfolio> // filled during init()
    let club: Organization
    @Binding var preferences: PreferencesStructHTML

    init(club: Organization, preferences: Binding<PreferencesStructHTML>) {
        // this init() happens when the club gets shown (or almost shown) in the sidebar panel of a NavigationSplitView
        self.club = club
        self._preferences = preferences

        // Core Data stuff. Match sort order used in Members to generate HTML
        let sortDescriptor1 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.givenName_, ascending: true)
        let sortDescriptor2 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)
        let predicate = NSPredicate(format: "organization_ = %@", argumentArray: [club])
        // https://www.youtube.com/watch?v=O4043RVjCGU HackingWithSwift session on dynamic Core Data fetch requests:
        _fetchRequestClubMembers = FetchRequest<MemberPortfolio>(sortDescriptors: [sortDescriptor1, sortDescriptor2],
                                                                 predicate: predicate)
    }

    var body: some View {
        List {
            if fetchRequestClubMembers.isEmpty {
                VStack(alignment: .center) {
                    HStack {
                        Spacer()
                        Text(String(localized: "Can't find any members for \(club.fullNameTown).",
                                    table: "PhotoClubHubHTML.SwiftUI",
                                    comment: "Shown when a club with zero known members is selected"))
                            .font(.title2)
                        Spacer()
                    }
                 }
                    .frame(idealHeight: 750) // a bit of a hack to get vertical alignment
            } else {
                ForEach(fetchRequestClubMembers, id: \.self) { member in
                    HStack {
                        Text(verbatim:
                             """
                             \(member.photographer_?.givenName_ ?? "given name?") \
                             \(infix(content: member.photographer_?.infixName))\
                             \(member.photographer_?.familyName_ ?? "family name?")\
                             \(describeMember(member: member))
                             """) .font(.title3) .fontWeight(.bold) .lineLimit(1)
                        Spacer()
                        Text(verbatim: "\(member.featuredImageThumbnail.path)")
                            .font(.footnote)
                            .lineLimit(1)
                    }
                }
            }
        }
        .onAppear { preferences.selectedClubNickname = club.nickName } // first time
        .onChange(of: club) { preferences.selectedClubNickname = club.nickName } // any subsequent change
    }

    private func infix(content: String?) -> String {
        if let content, content.isEmpty==false {
            return content + " "
        }
        return ""
    }

    private func describeMember(member: MemberPortfolio) -> String {
        if member.isFormerMember {
            let deceased = String(localized: "deceased",
                                  table: "PhotoClubHubHTML.SwiftUI",
                                  comment: "Textual indicator of a deceased person in app's UI")
            let former = String(localized: "former member",
                                table: "PhotoClubHubHTML.SwiftUI",
                                comment: "Textual indicator of a former member in app's UI")
            var output = " ("
            if member.photographer.isDeceased {
                output += deceased + " "
            }
            output += former
            output += ")"
            return output
        } else {
            return ""
        }
    }
}

// MARK: - Preview

// KNOWN ISSUE: this preview crashes (confirmed on macOS 26.5.1 + Xcode 26.6, and Xcode 27.0 beta 1).
// Root cause is an Apple toolchain bug, NOT this code. Bisecting with live renders showed:
//   - `Text(...)`, `List { Text }`, and reading CoreData attributes all preview fine.
//   - Rendering this view crashes the moment its body touches `@FetchRequest`/`FetchedResults`
//     (crashes even when the club has zero members, i.e. the ForEach is never iterated).
// The crash is a SIGSEGV inside Swift Concurrency's dynamic main-actor isolation check
// (swift_task_isCurrentExecutor -> isMainExecutor -> swift_getObjectType -> objc_msgSend).
// Under the normal app this check passes; under the Previews JIT runtime (XOJITExecutor) the
// executor identity is invalid and it faults. Triggered by SWIFT_STRICT_CONCURRENCY=complete /
// Swift 6 + @FetchRequest. Any view in this target using @FetchRequest will crash in Previews.
// Toggling SWIFT_UPCOMING_FEATURE_DYNAMIC_ACTOR_ISOLATION made no difference.
// The preview below is correct and should start working once Apple fixes the Previews bug.
#Preview {
    @Previewable @State var preferences = PreferencesStructHTML.defaultValue
    let viewContext = PersistenceController.preview.container.viewContext
    let club = Organization.addHardcodedFgDeGenderForPreview(context: viewContext)
    MembershipView(club: club, preferences: $preferences)
        .environment(\.managedObjectContext, viewContext)
}

extension Organization {

    private static func addFGdeGender(context: NSManagedObjectContext) -> Organization {
        let fgDeGenderIDPlus = OrganizationIdPlus(fullName: "Fotogroep de Gender",
                                                  town: "Eindhoven",
                                                  nickname: "FGdeGender")
        let fgDeGender = Organization.findCreateUpdate(context: context,
                                                       organizationTypeEnum: OrganizationTypeEnum.club,
                                                       idPlus: fgDeGenderIDPlus)
        do {
            try context.save()
            return fgDeGender
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    // this func cannot just be private because it is called from the View code
    fileprivate static func addHardcodedFgDeGenderForPreview(context: NSManagedObjectContext) -> Organization {
        let fgDeGender = addFGdeGender(context: context)

        let hansKrüsemannPN = PersonName(givenName: "Hans", infixName: "", familyName: "Krüsemann")
        let hansKrüsemannPho = Photographer.findCreateUpdate(context: context,
                                                             personName: hansKrüsemannPN,
                                                             optionalFields: PhotographerOptionalFields())
        let hansKrüsemannOpt = MemberOptionalFields(
            level3URL: URL(string: "http://www.vdhamer.com/fgDeGender/Hans_Krusemann/"),
            memberRolesAndStatus: MemberRolesAndStatus(roles: [ .admin: true ], status: [:]),
            fotobondMemberNumber: FotobondMemberNumber(id: 1620090),
            membershipStartDate: "2016-04-01".extractDate(),
            membershipEndDate: nil)
        _ = MemberPortfolio.findCreateUpdate(bgContext: context,
                                             organization: fgDeGender,
                                             photographer: hansKrüsemannPho,
                                             optionalFields: hansKrüsemannOpt)

        let jelleVanDeVoortPN = PersonName(givenName: "Jelle", infixName: "van de", familyName: "Voort")
        let jelleVanDeVoortPho = Photographer.findCreateUpdate(context: context,
                                                  personName: jelleVanDeVoortPN,
                                                  optionalFields: PhotographerOptionalFields())
        let jelleVanDeVoortOpt = MemberOptionalFields(
            level3URL: URL(string: "http://www.vdhamer.com/fgDeGender/Jelle_van_de_Voort/"),
            memberRolesAndStatus: MemberRolesAndStatus(roles: [ .chairman: true ], status: [:]),
            fotobondMemberNumber: FotobondMemberNumber(id: 1620103),
            membershipStartDate: "2020-01-01".extractDate(),
            membershipEndDate: nil)
        _ = MemberPortfolio.findCreateUpdate(bgContext: context,
                                             organization: fgDeGender,
                                             photographer: jelleVanDeVoortPho,
                                             optionalFields: jelleVanDeVoortOpt)

        let peterVanDenHamerPN = PersonName(givenName: "Peter", infixName: "van den", familyName: "Hamer")
        let peterVanDenHamerPho = Photographer.findCreateUpdate(context: context,
                                                  personName: peterVanDenHamerPN,
                                                  optionalFields: PhotographerOptionalFields(
                                                    bornDT: "1957-10-18".extractDate(),
                                                    photographerWebsite: URL(string: "https://glass.photo/vdhamer")
                                                  ))
        let peterVanDenHamerOpt = MemberOptionalFields(
            level3URL: URL(string: "http://www.vdhamer.com/fgDeGender/Peter_van_den_Hamer/"),
            memberRolesAndStatus: MemberRolesAndStatus(roles: [ .admin: true ], status: [:]),
            fotobondMemberNumber: FotobondMemberNumber(id: 1620110),
            membershipStartDate: "2024-01-01".extractDate(),
            membershipEndDate: nil)
        _ = MemberPortfolio.findCreateUpdate(bgContext: context,
                                             organization: fgDeGender,
                                             photographer: peterVanDenHamerPho,
                                             optionalFields: peterVanDenHamerOpt)
        return fgDeGender
    }

}
