//
//  Members.swift
//  Photo Club Hub - Ignite
//
//  Created by Peter van den Hamer on 06/09/2024.
//

import Foundation // for DateFormatter()
import Ignite // for StaticPage

// swiftlint:disable:next type_body_length
struct Members: StaticPage {
    var title = "Leden"
    private var currentMembersTotalYears: Double = 0 // updated in memberRow()
    private var currentMembersCount: Int = 0 // updated in memberRow(). Can this become a computed property?
    private var formerMembersTotalYears: Double = 0 // updated in memberRow()
    private var formerMembersCount: Int = 0 // updated in memberRow(). Can this become a computed property?
    private let dateFormatter = DateFormatter()
    private var currentMembers = Table {} // init to empty table, then fill during init()
    private var formerMembers = Table {} // same story

    // MARK: - init()

    // swiftlint:disable:next function_body_length
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd"

        currentMembers = Table { // Table is normally found in body(), but is stored here to compute length in time
            memberRow(givenName: "Albert", familyName: "Koning",
                      start: "2022-11-17", fotobond: 1620108,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Albert_Koning/",
                      thumbnailSuffix: "2023_untitled_shoot_004-2.jpg")

            memberRow(givenName: "Anke", familyName: "Spijkers",
                      start: "2002-04-01", fotobond: 1620059,
                      website: "http://www.ankefoto.nl/",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Anke_Spijkers/",
                      thumbnailSuffix: "DSC00576.jpg_k.jpg_klein.jpg")

            memberRow(givenName: "Bert", familyName: "Zantingh",
                      start: "1996-01-01", fotobond: 1620040,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Bert_Zantingh/",
                      thumbnailSuffix: "Groot_bord_2_Groeneveld_Lijst_60x50cm.jpg")

            memberRow(givenName: "Bettina", infixName: "de", familyName: "Graaf-de Vos",
                      start: "2024-01-01", fotobond: 1620111,
                      website: "https://glass.photo/jerdam",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Bettina_de_Graaf/",
                      thumbnailSuffix: "IMG_6060.jpg")

            memberRow(givenName: "Eric", infixName: "van de", familyName: "Ven",
                      start: "2022-12-01", fotobond: 1620109,
                      website: "https://www.ericvdven.nl",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Eric_van_de_Ven/",
                      thumbnailSuffix: "4-9_2.jpg")

            memberRow(givenName: "Francien", infixName: "van", familyName: "Mil",
                      start: "2019-09-22", fotobond: 1620099,
                      role: "Secretaris",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Francien_van_Mil/",
                      thumbnailSuffix: "_DSF0746.jpg")

            memberRow(givenName: "Gert", infixName: "du", familyName: "Bois",
                      start: "2015-01-01", fotobond: 1620087,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Gert_du_Bois/",
                      thumbnailSuffix: "2024_GertDuBois_002.jpg")

            memberRow(givenName: "Hans", infixName: "van", familyName: "Gorp",
                      start: "1995-01-01", fotobond: 1620029,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Hans_van_Gorp/",
                      thumbnailSuffix: "DSC_3086-2.jpg")

            memberRow(givenName: "Hans", familyName: "Krüsemann",
                      start: "2016-04-01", fotobond: 1620090,
                      role: "Bestuurslid",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Hans_Krusemann/",
                      thumbnailSuffix: "Kootwijkerzand-1.jpg")

            memberRow(givenName: "Jelle", infixName: "van de", familyName: "Voort",
                      start: "2020-01-01", fotobond: 1620103,
                      role: "Voorzitter",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Jelle_van_de_Voort/",
                      thumbnailSuffix: "IMG_8399.jpg")

            memberRow(givenName: "Joep", familyName: "Julicher",
                      start: "2019-04-01", fotobond: 1620098,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Joep_Julicher/",
                      thumbnailSuffix: "2051_40_rond.jpg")

            memberRow(givenName: "Lex", familyName: "Augusteijn",
                      start: "2005-01-01", fotobond: 1620064,
                      role: "Bestuurlid",
                      website: "https://www.lex-augusteijn.nl",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Lex_Augusteijn/",
                      thumbnailSuffix: "Luik_IMG_8061_Panorama.jpg")

            memberRow(givenName: "Mariet", familyName: "Wielders",
                      start: "2009-11-01", fotobond: 1620079,
                      website: "https://www.m3w.nl",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Mariet_Wielders/",
                      thumbnailSuffix: "Kuppermuhle_trapA.jpg")

            memberRow(givenName: "Marika", familyName: "Beckers-van Hout",
                      start: "2021-05-26", fotobond: 1620104,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Marika_Beckers/",
                      thumbnailSuffix: "fietswrak_dig.jpg")

            memberRow(givenName: "Martien", familyName: "Leenders",
                      start: "1990-01-01", fotobond: 1620008,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Martien_Leenders/",
                      thumbnailSuffix: "_DSC6612-01.jpgmodel_verz.jpg")

            memberRow(givenName: "Miep", familyName: "Franssen",
                      start: "1976-01-01", fotobond: 1620021,
                      role: "Erelid",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Miep_Franssen/",
                      thumbnailSuffix: "2023_untitled_shoot_001-2-Enhanced-SR.jpg")

            memberRow(givenName: "Peter", infixName: "van den", familyName: "Hamer",
                      start: "2024-01-01", fotobond: 1620110,
                      role: "Admin",
                      website: "https://glass.photo/vdhamer",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Peter_van_den_Hamer/",
                      thumbnailSuffix: "2023_Cornwall_R5_618-Edit-2.jpg")

            memberRow(givenName: "Peter", infixName: "de", familyName: "Wit",
                      start: "2022-10-30", fotobond: 1620107,
                      website: "https://www.flickr.com/photos/150047808@N08/albums",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Peter_de_Wit/",
                      thumbnailSuffix: "EXPO_2024_03_-_Eindhoven_NL_-_30Hx54B_-_1920x1080.jpg")

            memberRow(givenName: "Piet", infixName: "van der", familyName: "Putten",
                      start: "2008-04-01", fotobond: 1620076,
                      website: "http://www.pietvanderputtenfotografie.nl/",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Piet_van_der_Putten/",
                      thumbnailSuffix: "Piet_2024-3.jpg")

            memberRow(givenName: "Regina", familyName: "Bakker",
                      start: "2020-01-01", fotobond: 1620101,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Regina_Bakker/",
                      thumbnailSuffix: "R3-_20211113-IMG_2946-11-204-60x40_v2-4.jpg")

            memberRow(givenName: "Rob", infixName: "van", familyName: "Doorn",
                      start: "2017-10-23", fotobond: 1620093,
                      website: "http://www.rovado-artworks.nl/",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Rob_van_Doorn/",
                      thumbnailSuffix: "Rovado_-003-_ROB3872.jpg")

            memberRow(givenName: "Ton", familyName: "Buijs",
                      start: "2014-12-01", fotobond: 1620085,
                      website: "http://www.tonbuijs.nl/",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Ton_Buijs/",
                      thumbnailSuffix: "07.jpg")

            memberRow(givenName: "Ton", familyName: "Roovers",
                      start: "2022-10-27", fotobond: 1620106,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Ton_Roovers/",
                      thumbnailSuffix: "P1000329-2.jpg")

            memberRow(givenName: "Toon", familyName: "Mouws",
                      start: "1996-01-01", fotobond: 1620038,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Toon_Mouws/",
                      thumbnailSuffix: "_DSC0413-417.jpg")

            memberRow(givenName: "Truus", familyName: "Michielsen",
                      start: "2009-04-01", fotobond: 1620078,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Truus_Michielsen/",
                      thumbnailSuffix: "floris_bob-klein_tentoonstelling.jpg")

            memberRow(givenName: "Wim", familyName: "Heijne",
                      start: "2022-10-23", fotobond: 1620105,
                      role: "Penningmeester",
                      website: "https://www.flickr.com/photos/fotoklasje/",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Wim_Heijne/",
                      thumbnailSuffix: "2._Licht_reflectie_St_Pauluskathedraal_Luik_PANA4349.jpg")
        } header: {
            "Naam"
            "Jaren lid"
            "Eigen site"
            "Portfolio"
        }

        formerMembers = Table { // Table is normally found in body(), but is stored here to compute length in time
            memberRow(givenName: "Frans", familyName: "Verbeek",
                      start: "2004-01-01", end: "2023-12-31", fotobond: 1620061,
                      portfolio: "http://www.vdhamer.com/fgDeGender/Frans_Verbeek/",
                      thumbnailSuffix: "2017_GemeentehuisWaalre_5D2_33-Edit.jpg")

            memberRow(givenName: "Willem", infixName: "van", familyName: "Oranje",
                      start: "1533-04-24", end: "1584-07-10", fotobond: 0001001,
                      isDeceased: true,
                      website: "https://www.museumprinsenhofdelft.nl",
                      portfolio: "http://www.vdhamer.com/fgDeGender/Frans_Verbeek/",
                      thumbnailSuffix: "2017_GemeentehuisWaalre_5D2_33-Edit.jpg")
        } header: {
            "Naam"
            "Lid van-tot"
            "Eigen site"
            "Portfolio"
        }
    }

    // MARK: - body()

    func body(context: PublishingContext) -> [BlockElement] {

        // MARK: - current members

        Text {
            Badge("De \(currentMembersCount) huidige leden")
                .badgeStyle(.subtleBordered)
                .role(.success)
        }
        .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

        currentMembers // interpret this as an Ignite Table { } that returns [Rows]
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

        if currentMembersCount > 0 {
            Alert {
                Text {
                    """
                    Huidige leden zijn gemiddeld \
                    \(formatYears(years: currentMembersTotalYears/Double(currentMembersCount))) \
                    jaar lid.
                    """
                } .horizontalAlignment(.center)
            }
            .margin(.top, .small)
        }

        Divider() // don't know how to get it darker or in color

        // MARK: - former members

        Text {
            Badge("\(formerMembersCount) voormalige leden")
                .badgeStyle(.subtleBordered)
                .role(.secondary)
        }
        .font(.title2) .horizontalAlignment(.center) .margin([.top, .bottom], .large)

        formerMembers
            .tableStyle(.stripedRows)
            .tableBorder(true)
            .horizontalAlignment(.center)

        if formerMembersCount > 0 {
            Alert {
                Text {
                    """
                    De vermeldde ex-leden waren gemiddeld \
                    \(formatYears(years: formerMembersTotalYears/Double(formerMembersCount))) \
                    jaar lid.
                    """
                } .horizontalAlignment(.center)
            }
            .margin(.top, .small)
        }
    }

    func bestuursRol(row: Int) -> String {
        let mod = row % 8
        switch mod {
        case 0: return "Penningmeester"
        case 4: return "Voorzitter"
        default: return ""
        }
    }

    private mutating func memberRow(givenName: String,
                                    infixName: String = "",
                                    familyName: String,
                                    start: String,
                                    end: String? = nil, // nil means "still a member",
                                    fotobond: Int? = nil,
                                    isDeceased: Bool = false,
                                    role: String = "",
                                    website: String = "",
                                    portfolio: String,
                                    thumbnailSuffix: String) -> Row {
        return Row {
            Column {
                Group {
                    Text {
                        Link(
                            fullName(givenName: givenName, infixName: infixName, familyName: familyName)
                            , target: "\(portfolio)")
                        .linkStyle(.hover)
                        if isDeceased {
                            Badge("Overleden")
                                .badgeStyle(.default)
                                .role(.secondary)
                                .margin(.leading, 10)
                        } else {
                            Badge(role)
                                .badgeStyle(.subtleBordered)
                                .role(.success)
                                .margin(.leading, 10)
                        }
                    } .font(.title5)
                } .horizontalAlignment(.leading)
            } .verticalAlignment(.middle)

            Column {
                formatMembershipYears(start: start, end: end, fotobond: fotobond ?? 1234567)
            } .verticalAlignment(.middle)

            if website.isEmpty {
                Column { }
            } else {
                Column {
                    Span(
                        Link( "Website", target: website)
                            .linkStyle(.hover)
                            .role(.default)
                    )
                    .hint(text: website)
                } .verticalAlignment(.middle)
            }

            Column {
                Image(lastPathComponent(fullUrl: portfolio+"/thumb/"+thumbnailSuffix),
                      description: "clickable link to portfolio")
                    .resizable()
                    .cornerRadius(8)
                    .aspectRatio(.square, contentMode: .fill)
                    .frame(width: 80)
                    .style("cursor: pointer")
                    .onClick {
                        CustomAction("window.location.href=\"\(portfolio)\";")
                    }
            } .verticalAlignment(.middle)

        }
    }

    private func formatYears(years: Double) -> String {
        String(format: "%.1f", locale: Locale(identifier: "nl_NL"), years) // "1,2"
    }

    private mutating func formatMembershipYears(start: String, end: String?, fotobond: Int) -> Span {
        let endDate: Date = (end != nil) ? (dateFormatter.date(from: end!) ?? Date.now) : Date.now
        let dateInterval = DateInterval(start: dateFormatter.date(from: start) ?? Date.now, end: endDate)
        let years = dateInterval.duration / (365.25 * 24 * 60 * 60)
        if end == nil {
            currentMembersTotalYears += years
            currentMembersCount += 1
            return Span(formatYears(years: years))
                        .hint(text: "Vanaf \(start). Fotobond #\(fotobond).")
        } else {
            formerMembersTotalYears += years
            formerMembersCount += 1
            return Span("\(start.prefix(4))-\(end!.prefix(4))")
                   .hint(text: "Vanaf \(start) t/m \(end!) (\(formatYears(years: years)) jaar). Fotobond #\(fotobond).")
        }
    }

    private func fullName(givenName: String,
                          infixName: String = "",
                          familyName: String) -> String {

        if infixName.isEmpty {
            return givenName + " " + familyName
        } else {
            return givenName + " " + infixName + " " + familyName
        }
    }

    private func lastPathComponent(fullUrl: String) -> String {
        let url = URL(string: fullUrl)
        let lastComponent: String = url?.lastPathComponent ?? "error in lastPathComponent"
        return "/images/\(lastComponent)"
    }

}
