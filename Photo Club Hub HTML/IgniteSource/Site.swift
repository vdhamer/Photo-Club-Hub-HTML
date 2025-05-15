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
    // IMPORTANT: append "/fgDeGender" (nickname) to URL string unless running on LocalHost
    var url: URL = URL("http://www.vdhamer.com/")
    var builtInIconsEnabled: BootstrapOptions = .none
    var author = "Peter van den Hamer"
    var homePage: Members // actual loading of page content
    var theme = MyTheme()

    var moc: NSManagedObjectContext

    init(moc: NSManagedObjectContext) {
        let deGenderID = OrganizationID(fullName: "Fotogroep de Gender", town: "Eindhoven")
        let deGenderIDPlus = OrganizationIdPlus(id: deGenderID, nickname: "fgDeGender")
        let club0: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: OrganizationTypeEnum.club,
                                                                idPlus: deGenderIDPlus,
                                                                // real coordinates added in xxxxxxx.level2.json
                                                                coordinates: CLLocationCoordinate2DMake(0, 0),
                                                                optionalFields: OrganizationOptionalFields())

        let waalreID = OrganizationID(fullName: "Fotogroep Waalre", town: "Waalre")
        let waalreIDPlus = OrganizationIdPlus(id: waalreID, nickname: "fgWaalre")
        let club1: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: OrganizationTypeEnum.club,
                                                                idPlus: waalreIDPlus,
                                                                // real coordinates added in xxxxxxx.level2.json
                                                                coordinates: CLLocationCoordinate2DMake(0, 0),
                                                                optionalFields: OrganizationOptionalFields())

        let bellusImagoID = OrganizationID(fullName: "Fotoclub Bellus Imago", town: "Veldhoven")
        let bellusImagoIDPlus = OrganizationIdPlus(id: bellusImagoID, nickname: "fcBellusImago")
        let club2: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: OrganizationTypeEnum.club,
                                                                idPlus: bellusImagoIDPlus,
                                                                // real coordinates added in xxxxxxx.level2.json
                                                                coordinates: CLLocationCoordinate2DMake(0, 0),
                                                                optionalFields: OrganizationOptionalFields())

        self.moc = moc

        let chosenClubIX: Int = 0  // roundabout way to avoid warnings about unused properties
        let clubs = [club0, club1, club2]
        let club = clubs[max(min(chosenClubIX, clubs.count - 1), 0)] // clip to array bounds in case index is wrong

        self.homePage = Members(moc: moc, club: club)
    }
}
