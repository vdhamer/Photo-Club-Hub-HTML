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

    let name: String = "Leden"
    let url: URL
    let builtInIconsEnabled: BootstrapOptions = .localBootstrap
    let author = "Peter van den Hamer"
    let homePage: Members
    let theme = MyTheme()
    let clubType: OrganizationTypeEnum = OrganizationTypeEnum.club

    let moc: NSManagedObjectContext
    let preferences: PreferencesStructHTML

    let pages: [any StaticPage] // precomputed to avoid Core Data queries on wrong threads

    // swiftlint:disable:next function_body_length
    init(moc: NSManagedObjectContext, preferences: PreferencesStructHTML) {
        // examples: "http://localhost:8000", "https://www.fcDeGender.nl", etc.
        url = preferences.selectedHost.url(forPath: preferences.selectedClubNickname) ??
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

        // MARK: - Get all languages
        let languageFetch: NSFetchRequest<Photo_Club_Hub_Data.Language> = Photo_Club_Hub_Data.Language.fetchRequest()
        languageFetch.sortDescriptors = [NSSortDescriptor(key: "isoCode_", ascending: true)] // for determinism only
        let languages = (try? moc.fetch(languageFetch)) ?? []
        if languages.isEmpty {
            ifDebugFatalError("No languages found in Level2Site()")
        } else {
            for language in languages where language.isoCode != language.isoCode.lowercased() { // just a safety guard
                    ifDebugFatalError("Bad isoCode (not lowercase): \(language.isoCode)")
            }
        }

        // MARK: - Get all expertises
        let expertiseFetch: NSFetchRequest<Expertise> = Expertise.fetchRequest()
        expertiseFetch.sortDescriptors = [NSSortDescriptor(key: "id_", ascending: true)]
        let expertises = (try? moc.fetch(expertiseFetch)) ?? []
        if expertises.isEmpty {
            ifDebugFatalError("No expertises found in Level2Site()")
        }

        let club: Organization = (try? Organization.find(context: moc, nickname: preferences.selectedClubNickname))
                               ?? (try? Organization.find(context: moc, nickname: "TemplateMin"))
                               ?? club0

        let homeLanguageID = languages.first?.isoCode ?? "nl"
        self.homePage = Members(moc: moc, club: club, languageID: homeLanguageID, preferences: preferences)

        // Only generate a Members page for a language if that language has at least one expertise translation.
        // This keeps Level 2 output in sync with Level 0 —
        // you won't get a German club page unless there is at least one German expertise label to show.
        var pageList: [any StaticPage] = []
        for language in languages where expertises.contains(
            where: { LocalizedExpertise.exists(context: moc, expertiseID: $0.id, languageIsoCode: language.isoCode) }
        ) {
            pageList.append(Members(moc: moc, club: club, languageID: language.isoCode, preferences: preferences))
        }
        self.pages = pageList
    }

}
