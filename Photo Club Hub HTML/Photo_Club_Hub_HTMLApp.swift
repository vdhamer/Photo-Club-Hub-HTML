//
//  Photo_Club_Hub_HTMLApp.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 07/09/2024.
//

import SwiftUI
import Ignite

@main
struct PhotoClubHubHtmlApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        OrganizationType.initConstants() // creates records for club, museum, and unknown
    }

        /*
        {
            "name": {
                "givenName": "Hans",
                "infixName": "",
                "familyName": "Krüsemann"
            },
            "optional": {
                "level3URL": "http://www.vdhamer.com/fgDeGender/Hans_Krusemann/",
                "roles": {
                    "isOther": true
                },
                "membershipStartDate": "2016-04-01",
                "nlSpecific": {
                    "fotobondNumber": 1620090
                }
            }
        }

        {
            "name": {
                "givenName": "Jelle",
                "infixName": "van de",
                "familyName": "Voort"
            },
            "optional": {
                "level3URL": "http://www.vdhamer.com/fgDeGender/Jelle_van_de_Voort/",
                "roles": {
                    "isChairman": true
                },
                "membershipStartDate": "2020-01-01",
                "nlSpecific": {
                    "fotobondNumber": 1620103
                }
            }
        }
    }

    {
        "name": {
            "givenName": "Peter",
            "infixName": "van den",
            "familyName": "Hamer"
        },
        "optional": {
            "birthday": "1957-10-18",
            "website": "https://glass.photo/vdhamer",
            "level3URL": "http://www.vdhamer.com/fgDeGender/Peter_van_den_Hamer/",
            "roles": {
                "isAdmin": true
            },
            "membershipStartDate": "2024-01-01",
            "nlSpecific": {
                "fotobondNumber": 1620110
            }
        }
    } */

    var body: some Scene {
        Window("Photo Club Hub HTML", id: "mainWindow") {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .undoRedo) { }
            CommandGroup(replacing: .help) { }
            CommandGroup(replacing: .systemServices) { }
        }
    }
}
