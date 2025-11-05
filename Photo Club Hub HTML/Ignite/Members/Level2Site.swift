//
//  Level2Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import Ignite // for Site

import SwiftUI // for @State
import CoreData // for NSManagedObjectContext
import Photo_Club_Hub_Data // for Organization

struct Level2Site: Site {

    var name: String = "Leden" // set during init()
    // NOTE: https://www.fcDeGender.nl gives localhost result, https://www.fcDeGender.nl/fgDeGender works on remote site
    var url: URL = URL("https://www.fcDeGender.nl/fgDeGender")
    var builtInIconsEnabled: BootstrapOptions = .localBootstrap
    var author = "Peter van den Hamer"
    let homePage: Members
    var theme = MyTheme()

    var moc: NSManagedObjectContext
    let club: OrganizationTypeEnum = OrganizationTypeEnum.club

    // swiftlint:disable:next function_body_length
    init(moc: NSManagedObjectContext) {

        let deGenderIdPlus = OrganizationIdPlus(fullName: "Fotogroep de Gender",
                                                town: "Eindhoven",
                                                nickname: "fgDeGender")
        let club0: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: club,
                                                                idPlus: deGenderIdPlus)

        let waalreIdPlus = OrganizationIdPlus(fullName: "Fotogroep Waalre",
                                              town: "Waalre",
                                              nickname: "fgWaalre")
        let club1: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: club,
                                                                idPlus: waalreIdPlus)

        let bellusImagoIdPlus = OrganizationIdPlus(fullName: "Fotoclub Bellus Imago",
                                                   town: "Veldhoven",
                                                   nickname: "fcBellusImago")
        let club2: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: club,
                                                                idPlus: bellusImagoIdPlus)

        let xampleMinIdPlus = OrganizationIdPlus(fullName: "Xample Club With Minimal Data",
                                                 town: "Amsterdam",
                                                 nickname: "XampleMin")
        let club3: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: club,
                                                                idPlus: xampleMinIdPlus)

        let xampleMaxIdPlus = OrganizationIdPlus(fullName: "Xample Club With Maximal Data",
                                                 town: "Rotterdam",
                                                 nickname: "XampleMax")
        let club4: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: club,
                                                                idPlus: xampleMaxIdPlus)

        let ericameraIdPlus = OrganizationIdPlus(fullName: "Fotoclub Ericamera",
                                                 town: "Eindhoven",
                                                 nickname: "fcEricamera")
        let club5: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: club,
                                                                idPlus: ericameraIdPlus)

        let oirschotIdPlus = OrganizationIdPlus(fullName: "Fotogroep Oirschot",
                                                town: "Oirschot",
                                                nickname: "fgOirschot")
        let club6: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: club,
                                                                idPlus: oirschotIdPlus)

        let dendungenIdPlus = OrganizationIdPlus(fullName: "Fotoclub Den Dungen",
                                                 town: "Den Dungen",
                                                 nickname: "fcDenDungen")
        let club7: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: club,
                                                                idPlus: dendungenIdPlus)

        let individueelBOIdPlus = OrganizationIdPlus(fullName: "Individuele Leden Brabant Oost",
                                                     town: "Brabant Oost",
                                                     nickname: "IndividueelBO")
        let club8: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: club,
                                                                idPlus: individueelBOIdPlus)

        let gestelIdPlus = OrganizationIdPlus(fullName: "Fotokring Sint-Michielsgestel",
                                              town: "Sint-Michielsgestel",
                                              nickname: "fkGestel")
        let club9: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: club,
                                                                idPlus: gestelIdPlus)

        self.moc = moc

        let chosenClubIX: Int = 0 // roundabout way to avoid SwiftLint warnings about unused properties
        let clubs = [club0, club1, club2, club3, club4, club5, club6, club7, club8, club9]
        let club = clubs[max(min(chosenClubIX, clubs.count - 1), 0)] // clip to array bounds in case index is wrong

        self.homePage = Members(moc: moc, club: club)
    }

}
