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

struct MemberSite: Site {
    var name = "Leden"
    var url: URL = URL("https://www.vdhamer.com") // append "/fgDeGender" etc when not running on LocalHost
    var builtInIconsEnabled: BootstrapOptions = .none
    var author = "Peter van den Hamer"
    var homePage: Members // actual loading of page content
    var theme = MyTheme()

    var moc: NSManagedObjectContext

    init(moc: NSManagedObjectContext) {
        let deGenderID = OrganizationID(fullName: "Fotogroep de Gender", town: "Eindhoven")
        let deGenderIDPlus = OrganizationIdPlus(id: deGenderID, nickname: "fgDeGender")
        let club: Organization = Organization.findCreateUpdate(context: moc,
                                                               organizationTypeEnum: OrganizationTypeEnum.club,
                                                               idPlus: deGenderIDPlus,
                                                               // real coordinates added in fgAnders.level2.json
                                                               coordinates: CLLocationCoordinate2DMake(0, 0),
                                                               optionalFields: OrganizationOptionalFields())

//        let waalreID = OrganizationID(fullName: "Fotogroep Waalre", town: "Waalre")
//        let waalreIDPlus = OrganizationIdPlus(id: waalreID, nickname: "fgWaalre")
//        let club: Organization = Organization.findCreateUpdate(context: moc,
//                                                               organizationTypeEnum: OrganizationTypeEnum.club,
//                                                               idPlus: waalreIDPlus,
//                                                               // real coordinates added in fgAnders.level2.json
//                                                               coordinates: CLLocationCoordinate2DMake(0, 0),
//                                                               optionalFields: OrganizationOptionalFields())

        self.moc = moc
        self.homePage = Members(moc: moc, club: club)
    }
}
