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
    @Environment(\.managedObjectContext) fileprivate var viewContext

    @FetchRequest var fetchRequestClubMembers: FetchedResults<MemberPortfolio> // filled during init()
    let club: Organization

    init(club: Organization) {
        // this init() happens when the club gets shown (or almost shown) in the sidebar panel of a NavigationSplitView
        self.club = club
        // match sort order used in Members to generate HTML
        let sortDescriptor1 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.givenName_, ascending: true)
        let sortDescriptor2 = NSSortDescriptor(keyPath: \MemberPortfolio.photographer_?.familyName_, ascending: true)
        let predicate = NSPredicate(format: "organization_ = %@", argumentArray: [club])
        // https://www.youtube.com/watch?v=O4043RVjCGU HackingWithSwift session on dynamic Core Data fetch requests:
        _fetchRequestClubMembers = FetchRequest<MemberPortfolio>(sortDescriptors: [sortDescriptor1, sortDescriptor2],
                                                                 predicate: predicate,
                                                                 animation: .bouncy(duration: 1))
    }

    var body: some View {
        List {
            if fetchRequestClubMembers.isEmpty {
                VStack(alignment: .center) {
                    HStack {
                        Spacer()
                        Text(String(localized: "Can't find any members for \(club.fullNameTown).", table: "SwiftUI",
                                    comment: "Shown when a club with zero known members is selected"))
                            .font(.title2)
                        Spacer()
                    }
                } .frame(idealHeight: 750) // a bit of a hack to vertically align
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
    }

    fileprivate func infix(content: String?) -> String {
        if let content, content.isEmpty==false {
            return content + " "
        }
        return ""
    }

    fileprivate func describeMember(member: MemberPortfolio) -> String {
        if member.isFormerMember {
            var output = " ("
            if member.photographer.isDeceased {
                output += "deceased "
            }
            output += "former member"
            output += ")"
            return output
        } else {
            return ""
        }
    }
}

// MARK: - Preview

 #Preview {
     @Previewable @Environment(\.managedObjectContext) var viewContext
     let fgDeGender = Organization.addHardcodedFgDeGenderForPreview(context: viewContext)
     MembershipView(club: fgDeGender)
 }

extension Organization {

     fileprivate static func addFGdeGender(context: NSManagedObjectContext) -> Organization {
        withAnimation {
            let fgDeGenderIDPlus = OrganizationIdPlus(fullName: "Fotogroep de Gender",
                                                      town: "Eindhoven",
                                                      nickname: "FGdeGender")

            let fgDeGender = Organization.findCreateUpdate(context: context, // foreground
                                                           organizationTypeEnum: OrganizationTypeEnum.club,
                                                           idPlus: fgDeGenderIDPlus)
            do {
                try context.save()
                return fgDeGender
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use
                // this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    fileprivate static func addHardcodedFgDeGenderForPreview(context: NSManagedObjectContext) -> Organization {
        let fgDeGender = addFGdeGender(context: context)

        let hansKrüsemannPN = PersonName(givenName: "Hans", infixName: "", familyName: "Krüsemann")
        let hansKrüsemannPho = Photographer.findCreateUpdate(context: context,
                                                             personName: hansKrüsemannPN,
                                                             optionalFields: PhotographerOptionalFields())
        let hansKrüsemannOpt = MemberOptionalFields(
            level3URL: URL(string: "http://www.vdhamer.com/fgDeGender/Hans_Krusemann/"),
            memberRolesAndStatus: MemberRolesAndStatus(roles: [ .admin: true ], status: [:]),
            fotobondNumber: 1620090,
            membershipStartDate: "2016-04-01".extractDate(),
            membershipEndDate: nil)
        let hansKrüsemannMem = MemberPortfolio.findCreateUpdate(bgContext: context,
                                                                organization: fgDeGender,
                                                                photographer: hansKrüsemannPho,
                                                                optionalFields: hansKrüsemannOpt)
        hansKrüsemannMem.refreshFirstImage()

        let jelleVanDeVoortPN = PersonName(givenName: "Jelle", infixName: "van de", familyName: "Voort")
        let jelleVanDeVoortPho = Photographer.findCreateUpdate(context: context,
                                                  personName: jelleVanDeVoortPN,
                                                  optionalFields: PhotographerOptionalFields())
        let jelleVanDeVoortOpt = MemberOptionalFields(
            level3URL: URL(string: "http://www.vdhamer.com/fgDeGender/Jelle_van_de_Voort/"),
            memberRolesAndStatus: MemberRolesAndStatus(roles: [ .chairman: true ], status: [:]),
            fotobondNumber: 1620103,
            membershipStartDate: "2020-01-01".extractDate(),
            membershipEndDate: nil)
        let jelleVanDeVoortMem = MemberPortfolio.findCreateUpdate(bgContext: context,
                                                                organization: fgDeGender,
                                                                photographer: jelleVanDeVoortPho,
                                                                optionalFields: jelleVanDeVoortOpt)
        jelleVanDeVoortMem.refreshFirstImage()

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
            fotobondNumber: 1620110,
            membershipStartDate: "2024-01-01".extractDate(),
            membershipEndDate: nil)
        let peterVanDenHamerMem = MemberPortfolio.findCreateUpdate(bgContext: context,
                                                                organization: fgDeGender,
                                                                photographer: peterVanDenHamerPho,
                                                                optionalFields: peterVanDenHamerOpt)
        peterVanDenHamerMem.refreshFirstImage()
        return fgDeGender
    }

}
