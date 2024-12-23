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
        // does this club use JuicBox Pro xml files?
        let clubsUsingJuiceBox: [OrganizationID] = [ // careful: ID strings have to be precise
            OrganizationID(fullName: "Fotogroep Waalre", town: "Waalre"),
            OrganizationID(fullName: "Fotogroep de Gender", town: "Eindhoven")
        ]
        guard clubsUsingJuiceBox.contains(organization.id) else { return }
        guard let urlOfImageIndex = URL(string: self.level3URL.absoluteString + "config.xml") else { return }

        // assumes JuiceBox Pro is used
        ifDebugPrint("""
                     \(self.organization.fullNameTown): starting refreshFirstImage() \
                     \(urlOfImageIndex.absoluteString) in background
                     """)

        let url = urlOfImageIndex // just switching to shorter name

        do {
            let xmlContent = try await Loader().UTF8UrlToString(from: url)
            parseXMLContent(xmlContent: xmlContent, member: self)
            ifDebugPrint(
                "\(self.organization.fullNameTown): completed refreshFirstImage() \(urlOfImageIndex.absoluteString)"
            )
        } catch {
            ifDebugFatalError("Failure in UTFUrlToString: \(error)")
        }

        struct Loader {
            let session: URLSession

            init() {
                self.session = URLSession.shared
            }

            func UTF8UrlToString(from url: URL) async throws -> String {
                let (data, _) = try await session.data(from: url)
                let string: String? = String(data: data, encoding: .utf8)
                return string ?? "Could not decode \(url) as UTF8" // not very helpful if you parse this as XML ;-(
            }
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
