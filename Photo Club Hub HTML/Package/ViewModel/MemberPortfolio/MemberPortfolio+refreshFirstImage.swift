//
//  MemberPortfolio+refreshFirstImage.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 20/10/2023.
//

import Foundation // for URL, URLSession, Data
import RegexBuilder // for OneOrMore, Capture, etc

extension MemberPortfolio {

    func refreshFirstImage() async throws {
        let clubsUsingJuiceBox: [OrganizationID] = [ // strings have to be precise ;-)
            OrganizationID(fullName: "Fotogroep Waalre", town: "Waalre"),
            OrganizationID(fullName: "Fotogroep de Gender", town: "Eindhoven")
        ]
        guard clubsUsingJuiceBox.contains(organization.id) else { return }
        let organizationTown: String = self.organization.fullNameTown

        if let urlOfImageIndex = URL(string: self.level3URL.absoluteString + "config.xml") {
            // assumes JuiceBox Pro is used
            ifDebugPrint("""
                         \(organizationTown): starting refreshFirstImage() \
                         \(urlOfImageIndex.absoluteString) in background
                         """)

            let url = urlOfImageIndex
//            let url = URL(string: "http://www.vdhamer.com/fgDeGender/Peter_van_den_Hamer/config.xml")!

            let xmlContent = try await Loader().UTF8UrlToString(from: url)
//            print(xmlContent)

            struct Loader {
                let session = URLSession.shared

                func UTF8UrlToString(from url: URL) async throws -> String {

                    let (data, _) = try await session.data(from: url)
                    let string: String? = String(data: data, encoding: .utf8)
                    return string ?? "Could not decode \(url) as UTF8" // not very helpful if you parse this as XML ;-(
                }
            }

            parseXMLContent(xmlContent: xmlContent, member: self)
            ifDebugPrint("\(organizationTown): completed refreshFirstImage() \(urlOfImageIndex.absoluteString)")
        }
    }

    fileprivate func parseXMLContent(xmlContent: String, member: MemberPortfolio) { // sample data
        //    <?xml version="1.0" encoding="UTF-8"?>
        //    <juiceboxgallery
        //                 galleryTitlePosition="NONE"
        //                     showOverlayOnLoad="false"
        //                     :
        //                     imageTransitionType="CROSS_FADE"
        //         >
        //             <image imageURL="images/image1.jpg" thumbURL="thumbs/image1.jpg" linkURL="" linkTarget="_blank">
        //             <title><![CDATA[]]></title>
        //             <caption><![CDATA[2022]]></caption>
        //         </image>
        //             <image imageURL="images/image2.jpg" thumbURL="thumbs/image2.jpg" linkURL="" linkTarget="_blank">
        //             <title><![CDATA[]]></title>
        //             <caption><![CDATA[2022]]></caption>
        //     </juiceboxgallery>

        let regex = Regex {
            "<image imageURL=\""
            Capture {
                "images/"
                OneOrMore(.any, .reluctant)
            }
            "\"" // closing double quote
            OneOrMore(.horizontalWhitespace)
            "thumbURL=\""
            Capture {
                "thumbs/"
                OneOrMore(.any, .reluctant)
            }
            "\"" // closing double quote
        }

        guard let match = try? regex.firstMatch(in: xmlContent) else {
            print("\(organization.fullName): ERROR - could not find image in parseXMLContent() " +
                  "for \(member.photographer.fullNameFirstLast) in \(member.organization.fullName)")
            return
        }
        let (_, imageSuffix, thumbSuffix) = match.output
        let imageURL = URL(string: self.level3URL.absoluteString + imageSuffix)
        let thumbURL = URL(string: self.level3URL.absoluteString + thumbSuffix)

        if member.featuredImage != imageURL && imageURL != nil {
            member.featuredImage = imageURL // this is where it happens.
            print("\(organization.fullName): found new image \(imageURL!)")
        }
        if member.featuredImageThumbnail != thumbURL && thumbURL != nil {
            member.featuredImageThumbnail = thumbURL // this is where it happens.
            print("\(organization.fullName): found new thumbnail \(thumbURL!)")
        }
    }

}
