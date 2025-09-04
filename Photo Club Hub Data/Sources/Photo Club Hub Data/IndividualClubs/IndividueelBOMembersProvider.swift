//
//  IndividueelBOMemebersProvider.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 06/07/2025.
//

import CoreData // for PersistenceController

final public class IndividueelBOMembersProvider: Sendable {

    public init(bgContext: NSManagedObjectContext,
                isBeingTested: Bool,
                useOnlyFileInBundle: Bool = false,
                randomTownForTesting: String? = nil) {

        if isBeingTested {
            guard let randomTownForTesting else {
                ifDebugFatalError("Missing randomTownForTesting", file: #file, line: #line)
                return
            }
            bgContext.performAndWait { // execute block synchronously
                insertOnlineMemberData(bgContext: bgContext,
                                       isBeingTested: isBeingTested,
                                       town: randomTownForTesting,
                                       useOnlyFileInBundle: useOnlyFileInBundle)
            }
        } else {
            bgContext.perform { // ... or execute same block asynchronously
                self.insertOnlineMemberData(bgContext: bgContext,
                                            isBeingTested: isBeingTested,
                                            useOnlyFileInBundle: useOnlyFileInBundle)
            }
        }

    }

    fileprivate func insertOnlineMemberData(bgContext: NSManagedObjectContext,
                                            isBeingTested: Bool,
                                            town: String = "Brabant Oost",
                                            useOnlyFileInBundle: Bool) {
        let idPlus = OrganizationIdPlus(fullName: "Individuele Leden Brabant Oost",
                                        town: town,
                                        nickname: "IndividueelBO")

        let club = Organization.findCreateUpdate(context: bgContext,
                                                 organizationTypeEnum: .club,
                                                 idPlus: idPlus
                                                )
        ifDebugPrint("\(club.fullNameTown): Starting insertOnlineMemberData() in background")

        _ = Level2JsonReader(bgContext: bgContext,
                             organizationIdPlus: idPlus,
                             isBeingTested: isBeingTested,
                             useOnlyFileInBundle: useOnlyFileInBundle)
        do {
            try bgContext.save()
        } catch {
            ifDebugFatalError("Failed to save club \(idPlus.nickname)", file: #fileID, line: #line)
        }

    }

}
