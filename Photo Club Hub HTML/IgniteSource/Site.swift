//
//  Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import Ignite // for Site

import SwiftUI // for @State
import CoreData // for NSManagedObjectContext
import CoreLocation // for CLLocationCoordinate2DMake
import Photo_Club_Hub_Data // for Organization

struct MemberSite: Site {
    var name = "Leden"
    // IMPORTANT: http://www.vdhamer.com gives localhost result, http://www.vdhamer.com/fgDeGender works on remote site
    var url: URL = URL("http://www.vdhamer.com")
    var builtInIconsEnabled: BootstrapOptions = .none
    var author = "Peter van den Hamer"
    var homePage: Members // actual loading of page content
    var theme = MyTheme()

    var moc: NSManagedObjectContext

    init(moc: NSManagedObjectContext) {

        let deGenderIDPlus = OrganizationIdPlus(fullName: "Fotogroep de Gender",
                                                town: "Eindhoven", nickname: "fgDeGender")
        let club0: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: OrganizationTypeEnum.club,
                                                                idPlus: deGenderIDPlus,
                                                                // real coordinates added in xxxxxxx.level2.json
                                                                coordinates: CLLocationCoordinate2DMake(0, 0),
                                                                optionalFields: OrganizationOptionalFields())

        let waalreIDPlus = OrganizationIdPlus(fullName: "Fotogroep Waalre",
                                              town: "Waalre", nickname: "fgWaalre")
        let club1: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: OrganizationTypeEnum.club,
                                                                idPlus: waalreIDPlus,
                                                                // real coordinates added in xxxxxxx.level2.json
                                                                coordinates: CLLocationCoordinate2DMake(0, 0),
                                                                optionalFields: OrganizationOptionalFields())

        let bellusImagoIDPlus = OrganizationIdPlus(fullName: "Fotoclub Bellus Imago",
                                                   town: "Veldhoven", nickname: "fcBellusImago")
        let club2: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: OrganizationTypeEnum.club,
                                                                idPlus: bellusImagoIDPlus,
                                                                // real coordinates added in xxxxxxx.level2.json
                                                                coordinates: CLLocationCoordinate2DMake(0, 0),
                                                                optionalFields: OrganizationOptionalFields())

        let xampleMinIDPlus = OrganizationIdPlus(fullName: "Xample Club With Minimal Data",
                                                 town: "Rotterdam", nickname: "XampleMin")
        let club3: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: OrganizationTypeEnum.club,
                                                                idPlus: xampleMinIDPlus,
                                                                // real coordinates added in xxxxxxx.level2.json
                                                                coordinates: CLLocationCoordinate2DMake(0, 0),
                                                                optionalFields: OrganizationOptionalFields())

        let xampleMaxIDPlus = OrganizationIdPlus(fullName: "Xample Club With Maximal Data",
                                                 town: "Amsterdam", nickname: "XampleMax")
        let club4: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: OrganizationTypeEnum.club,
                                                                idPlus: xampleMaxIDPlus,
                                                                // real coordinates added in xxxxxxx.level2.json
                                                                coordinates: CLLocationCoordinate2DMake(0, 0),
                                                                optionalFields: OrganizationOptionalFields())

        self.moc = moc

        let chosenClubIX: Int = 3  // roundabout way to avoid SwiftLint warnings about unused properties
        let clubs = [club0, club1, club2, club3, club4]
        let club = clubs[max(min(chosenClubIX, clubs.count - 1), 0)] // clip to array bounds in case index is wrong

        self.homePage = Members(moc: moc, club: club)
    }

}
