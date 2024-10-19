//
//  AddClubs.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 19/10/2024.
//

import Foundation
import SwiftUI

extension Organization {

     private static func addFGdeGender(context: NSManagedObjectContext) -> Organization {
        withAnimation {
            let organizationIdPlus = OrganizationIdPlus(fullName: "Fotogroep de Gender",
                                                        town: "Eindhoven",
                                                        nickname: "FGdeGender")

            let fgDeGender = Organization.findCreateUpdate(context: context, // foreground
                                                           organizationTypeEnum: OrganizationTypeEnum.club,
                                                           idPlus: organizationIdPlus,
                                                           optionalFields: OrganizationOptionalFields())
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

    private static func addFGWaalre(context: NSManagedObjectContext) -> Organization {
        withAnimation {
            let organizationIdPlus = OrganizationIdPlus(fullName: "Fotogroep Waalre",
                                                        town: "Waalre",
                                                        nickname: "FGWaalre")

            let fgWaalre = Organization.findCreateUpdate(context: context, // foreground
                                                           organizationTypeEnum: OrganizationTypeEnum.club,
                                                           idPlus: organizationIdPlus,
                                                           optionalFields: OrganizationOptionalFields())
            do {
                try context.save()
                return fgWaalre
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use
                // this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    public static func addHardcodedFgWaalre(context: NSManagedObjectContext) -> Organization {
        let fgWaalre = addFGWaalre(context: context)

        let peterVanDenHamerPN = PersonName(givenName: "Peter", infixName: "van den", familyName: "Hamer")
        let peterVanDenHamerPho = Photographer.findCreateUpdate(context: context,
                                                  personName: peterVanDenHamerPN,
                                                  optionalFields: PhotographerOptionalFields(
                                                    bornDT: "1957-10-18".extractDate(),
                                                    photographerWebsite: URL(string: "https://glass.photo/vdhamer")
                                                  ))
        let peterVanDenHamerOpt = MemberOptionalFields(
            level3URL: URL(string: "http://www.vdhamer.com/fgDeGender/Peter_van_den_Hamer/"),
            memberRolesAndStatus: MemberRolesAndStatus(role: [ .admin: true ], status: [:]),
            fotobondNumber: 1620110,
            membershipStartDate: "2024-01-01".extractDate(),
            membershipEndDate: nil)
        let peterVanDenHamerMem = MemberPortfolio.findCreateUpdate(bgContext: context,
                                                                organization: fgWaalre,
                                                                photographer: peterVanDenHamerPho,
                                                                optionalFields: peterVanDenHamerOpt)
        peterVanDenHamerMem.refreshFirstImage()
        return fgWaalre
    }

    public static func addHardcodedFgDeGender(context: NSManagedObjectContext) -> Organization {
        let fgDeGender = addFGdeGender(context: context)

        let hansKrüsemannPN = PersonName(givenName: "Hans", infixName: "", familyName: "Krüsemann")
        let hansKrüsemannPho = Photographer.findCreateUpdate(context: context,
                                                  personName: hansKrüsemannPN,
                                                  optionalFields: PhotographerOptionalFields())
        let hansKrüsemannOpt = MemberOptionalFields(
            level3URL: URL(string: "http://www.vdhamer.com/fgDeGender/Hans_Krusemann/"),
            memberRolesAndStatus: MemberRolesAndStatus(role: [ .admin: true ], status: [:]),
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
            memberRolesAndStatus: MemberRolesAndStatus(role: [ .chairman: true ], status: [:]),
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
            memberRolesAndStatus: MemberRolesAndStatus(role: [ .admin: true ], status: [:]),
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
