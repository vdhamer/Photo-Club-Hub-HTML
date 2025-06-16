//
//  PhotographerKeywordTest.swift
//  Photo Club HubTests
//
//  Created by Peter van den Hamer on 26/02/2025.
//

import Testing
@testable import Photo_Club_Hub_Data
import CoreData // for NSManagedObjectContext

@MainActor @Suite("Tests the Core Data PhotographerKeyword class") struct PhotographerKeywordTests {

    fileprivate let context: NSManagedObjectContext
    fileprivate let photographer: Photographer

    init () {
        context = PersistenceController.shared.container.viewContext

        let personName = PersonName(givenName: String.random(length: 10), infixName: "", familyName: "UnitTestDummy")
        let optionalFields = PhotographerOptionalFields()
        photographer = Photographer.findCreateUpdate(context: context,
                                                     personName: personName,
                                                     optionalFields: optionalFields)
    }

    @Test("Create a random keyword for a random photographer") func addPhotographerKeyword() {

        let keywordID = String.random(length: 10).capitalized // internally keyword.id is capitalized
        let photographerKeyword = PhotographerExpertise.findCreateUpdate(
            context: context,
            photographer: photographer,
            keyword: Expertise.findCreateUpdateNonStandard(context: context, id: keywordID, name: [], usage: []))
        #expect(photographerKeyword.keyword.id == keywordID)
        #expect(photographerKeyword.photographer === photographer)
        #expect(photographerKeyword.photographer.givenName == photographer.givenName)
        #expect(photographerKeyword.photographer.infixName == photographer.infixName)
        #expect(photographerKeyword.photographer.familyName == photographer.familyName)
    }

    @Test("Attempt to create duplicate PhotographerExpertise") func duplicatePhotographerKeyword() {

        let keywordID = String.random(length: 10).capitalized // internally keyword.id is capitalized
        let photographerExpertise1 = PhotographerExpertise.findCreateUpdate(
            context: context,
            photographer: photographer,
            keyword: Expertise.findCreateUpdateNonStandard(context: context, id: keywordID, name: [], usage: []))
        #expect(photographerExpertise1.keyword.id == keywordID)
        #expect(photographerExpertise1.photographer === photographer)
        #expect(photographerExpertise1.photographer.givenName == photographer.givenName)
        #expect(photographerExpertise1.photographer.infixName == photographer.infixName)
        #expect(photographerExpertise1.photographer.familyName == photographer.familyName)
        PhotographerExpertise.save(context: context)

        let photographerExpertise2 = PhotographerExpertise.findCreateUpdate(
            context: context,
            photographer: photographer, // same photographer
            keyword: Expertise.findCreateUpdateNonStandard(context: context, id: keywordID,
                                                         name: [], usage: [])) // same keyword
        #expect(photographerExpertise2.keyword.id == keywordID)
        #expect(photographerExpertise2.photographer === photographer)
        #expect(photographerExpertise2.photographer.givenName == photographer.givenName)
        #expect(photographerExpertise2.photographer.infixName == photographer.infixName)
        #expect(photographerExpertise2.photographer.familyName == photographer.familyName)
        PhotographerExpertise.save(context: context)

        #expect(photographerExpertise1 == photographerExpertise2)
        #expect(PhotographerExpertise.count(context: context, keywordID: keywordID, photographer: photographer) == 1)
    }

}
