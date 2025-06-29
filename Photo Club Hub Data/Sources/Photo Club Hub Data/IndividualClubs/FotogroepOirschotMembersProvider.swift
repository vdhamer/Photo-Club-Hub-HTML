//
//  FotogroepOirschotMembersProvider.swift
//  Photo Club Hub Data
//
//  Created by Peter van den Hamer on 31/05/2025.
//

import CoreData // for PersistenceController

public class FotogroepOirschotMembersProvider {

    public init(bgContext: NSManagedObjectContext,
                useOnlyInBundleFile: Bool = true,
                synchronousWithRandomTown: Bool = false,
                randomTown: String = "RandomTown") {

        if synchronousWithRandomTown {
            bgContext.performAndWait { // ...or execute same block synchronously
                self.insertOnlineMemberData(bgContext: bgContext, town: randomTown)
            }
        } else {
            bgContext.perform { // execute block asynchronously...
                self.insertOnlineMemberData(bgContext: bgContext)
            }
        }

    }

    fileprivate func insertOnlineMemberData(bgContext: NSManagedObjectContext, town: String = "Oirschot") {
        let idPlus = OrganizationIdPlus(fullName: "Fotogroep Oirschot",
                                        town: town,
                                        nickname: "fgOirschot")

        let club = Organization.findCreateUpdate(context: bgContext,
                                                 organizationTypeEnum: .club,
                                                 idPlus: idPlus
                                                )
        ifDebugPrint("\(club.fullNameTown): Starting insertOnlineMemberData() in background")

        _ = Level2JsonReader(bgContext: bgContext,
                             organizationIdPlus: idPlus,
                             isInTestBundle: false,
                             useOnlyInBundleFile: false)
        do {
            try bgContext.save()
        } catch {
            ifDebugFatalError("Failed to save club \(idPlus.nickname)", file: #fileID, line: #line)
        }

    }

}
