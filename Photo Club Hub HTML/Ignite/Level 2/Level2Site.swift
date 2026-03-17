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
    // NOTE: https://www.fcDeGender.nl works for localhost, https://www.fcDeGender.nl/fgDeGender/ works for remote site
//    var url: URL = URL("https://www.fcDeGender.nl/fgDeGender/")
//    var url: URL = URL("http://www.vdhamer.com")
    var url: URL
    var builtInIconsEnabled: BootstrapOptions = .localBootstrap
    var author = "Peter van den Hamer"
    let homePage: Members
    var theme = MyTheme()
    let clubType: OrganizationTypeEnum = OrganizationTypeEnum.club

    var moc: NSManagedObjectContext
    let preferences: PreferencesStructHTML

    // swiftlint:disable:next function_body_length
    init(moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        // hostString examples: "http://localhost:8000", "https://www.fcDeGender.nl", etc.
        url = preferences.selectedHost.url(clubNickname: preferences.selectedClubNickname) ??
              URL(preferences.selectedHost.staticString)

        // MARK: - Club 0

        let deGenderIdPlus = OrganizationIdPlus(fullName: "Fotogroep de Gender",
                                                town: "Eindhoven",
                                                nickname: "fgDeGender")
        let club0: Organization = Organization.findCreateUpdate(context: moc,
                                                                organizationTypeEnum: clubType,
                                                                idPlus: deGenderIdPlus)

        // MARK: - Club 1

        let waalreIdPlus = OrganizationIdPlus(fullName: "Fotogroep Waalre",
                                              town: "Waalre",
                                              nickname: "fgWaalre")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: waalreIdPlus)

        // MARK: - Club 2

        let bellusImagoIdPlus = OrganizationIdPlus(fullName: "Fotoclub Bellus Imago",
                                                   town: "Veldhoven",
                                                   nickname: "fcBellusImago")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: bellusImagoIdPlus)

        // MARK: - Club 3

        let templateMinIdPlus = OrganizationIdPlus(fullName: "Template Club With Minimal Data",
                                                 town: "Amsterdam",
                                                 nickname: "TemplateMin")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: templateMinIdPlus)

        // MARK: - Club 4

        let templateMaxIdPlus = OrganizationIdPlus(fullName: "Template Club With Maximal Data",
                                                 town: "Rotterdam",
                                                 nickname: "TemplateMax")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: templateMaxIdPlus)

        // MARK: - Club 5

        let ericameraIdPlus = OrganizationIdPlus(fullName: "Fotoclub Ericamera",
                                                 town: "Eindhoven",
                                                 nickname: "fcEricamera")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: ericameraIdPlus)

        // MARK: - Club 6

        let oirschotIdPlus = OrganizationIdPlus(fullName: "Fotogroep Oirschot",
                                                town: "Oirschot",
                                                nickname: "fgOirschot")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: oirschotIdPlus)

        // MARK: - Club 7

        let dendungenIdPlus = OrganizationIdPlus(fullName: "Fotoclub Den Dungen",
                                                 town: "Den Dungen",
                                                 nickname: "fcDenDungen")
        _ = Organization.findCreateUpdate(context: moc,
                                           organizationTypeEnum: clubType,
                                           idPlus: dendungenIdPlus)

        // MARK: - Club 8

        let persoonlijk16IdPlus = OrganizationIdPlus(fullName: "Persoonlijke Leden Brabant Oost",
                                                     town: "Brabant Oost",
                                                     nickname: "Persoonlijk16")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: persoonlijk16IdPlus)

        // MARK: - Club 9

        let gestelIdPlus = OrganizationIdPlus(fullName: "Fotokring Sint-Michielsgestel",
                                              town: "Sint-Michielsgestel",
                                              nickname: "fkGestel")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: gestelIdPlus)

        // MARK: - Club 10

        let persoonlijk03IdPlus = OrganizationIdPlus(fullName: "Persoonlijke Leden Drenthe - Vechtdal",
                                                     town: "Drenthe - Vechtdal",
                                                     nickname: "Persoonlijk03")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: persoonlijk03IdPlus)

        // MARK: - Club 11

        let fcVeghelIdPlus = OrganizationIdPlus(fullName: "Fotoclub Veghel",
                                                     town: "Veghel",
                                                     nickname: "fcVeghel")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: fcVeghelIdPlus)

        // MARK: - Club 12

        let ffcShot71IdPlus = OrganizationIdPlus(fullName: "FFC Shot71",
                                                 town: "Berlicum",
                                                 nickname: "ffcShot71")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: ffcShot71IdPlus)

        // MARK: - Club 13

        let fegGemertIdPlus = OrganizationIdPlus(fullName: "Foto Expressie Groep Gemert",
                                                     town: "Gemert",
                                                     nickname: "fegGemert")
        _ = Organization.findCreateUpdate(context: moc,
                                          organizationTypeEnum: clubType,
                                          idPlus: fegGemertIdPlus)

        self.moc = moc
        self.preferences = preferences

        do {
            let club: Organization = try Organization.find(context: moc, nickname: preferences.selectedClubNickname)
            self.homePage = Members(moc: moc, club: club, preferences: preferences)
        } catch {
            if let club = try? Organization.find(context: moc, nickname: "TemplateMin") {
                self.homePage = Members(moc: moc, club: club, preferences: preferences)
            } else {
                self.homePage = Members(moc: moc, club: club0, preferences: preferences)
            }
        }
    }

}
