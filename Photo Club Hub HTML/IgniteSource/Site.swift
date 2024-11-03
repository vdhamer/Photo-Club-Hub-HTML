//
//  Site.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import Ignite // for Site

import SwiftUI // for @State
import CoreData // for NSManagedObjectContext

struct MemberSite: Site {
    var name = "Leden"
    var titleSuffix = " – Fotogroep de Gender"
    var url: URL = URL("https://www.vdhamer.com") // append /fgDeGender unless running on LocalHost
    var builtInIconsEnabled: BootstrapOptions = .none
    var author = "Peter van den Hamer"
    var homePage: Members // actual loading of page content
    var theme = MyTheme()

    var moc: NSManagedObjectContext

    init(moc: NSManagedObjectContext) {
        let deGenderID = OrganizationID(fullName: "Fotogroep de Gender", town: "Eindhoven") // TODOD club hardcoded
        let deGenderIDPlus = OrganizationIdPlus(id: deGenderID, nickname: "fgDeGender")
        let club: Organization = Organization.findCreateUpdate(context: moc,
                                                               organizationTypeEnum: OrganizationTypeEnum.club,
                                                               idPlus: deGenderIDPlus,
                                                               optionalFields: OrganizationOptionalFields())

        self.moc = moc
        self.homePage = Members(moc: moc, club: club)
    }
}
