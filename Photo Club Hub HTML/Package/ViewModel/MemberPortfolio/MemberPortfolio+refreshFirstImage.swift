//
//  MemberPortfolio+refreshFirstImage.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 20/10/2023.
//

import Foundation // for URL, URLSession, Data
import RegexBuilder // for OneOrMore, Capture, etc

extension MemberPortfolio {

    private static let clubsUsingJuiceBox: [OrganizationID] = [ // careful: ID strings have to be accurate to match
        OrganizationID(fullName: "Fotogroep Waalre", town: "Waalre"),
        OrganizationID(fullName: "Fotogroep de Gender", town: "Eindhoven")
    ]

    func refreshFirstImageAsync() async throws { // not used because it doesn't work reliably
        // only applies to clubs using JuiceBox Pro:
        guard MemberPortfolio.clubsUsingJuiceBox.contains(organization.id) else { return }
        guard let urlOfImageIndex = URL(string: self.level3URL.absoluteString + "config.xml") else { return }

        // assumes JuiceBox Pro is used
        ifDebugPrint("""
                     \(self.organization.fullNameTown): starting refreshFirstImage() \
                     \(urlOfImageIndex.absoluteString) in background
                     """)

        let url = urlOfImageIndex // just switching to shorter name

        var xmlContent = ""
        do {
            xmlContent = try await Loader().UTF8UrlToString(from: url)
        } catch {
            ifDebugFatalError("Failure in UTFUrlToString: \(error)")
        }
        parseXMLContent(xmlContent: xmlContent, member: self)
        ifDebugPrint(
            "\(self.organization.fullNameTown): completed refreshFirstImage() \(urlOfImageIndex.absoluteString)"
        )

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

    func refreshFirstImageSync() {
        // only applies to clubs using JuiceBox Pro:
        guard MemberPortfolio.clubsUsingJuiceBox.contains(organization.id) else { return }
        guard let urlOfImageIndex = URL(string: self.level3URL.absoluteString + "config.xml") else { return }

        // assumes JuiceBox Pro is used
        ifDebugPrint("""
                 \(self.organization.fullNameTown): starting refreshFirstImage() \
                 \(urlOfImageIndex.absoluteString) in background
                 """)

        // swiftlint:disable:next large_tuple
        var results: (utfContent: Data?, urlResponse: URLResponse?, error: (any Error)?)? = (nil, nil, nil)
        results = URLSession.shared.synchronousDataTask(from: urlOfImageIndex)
        guard results != nil && results!.utfContent != nil else {
            print("""
              \(organization.fullNameTown): ERROR - \
              loading refreshFirstImage() \(urlOfImageIndex.absoluteString) failed
              """)
            return
        }

        let xmlContent = String(data: results!.utfContent! as Data,
                                encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        parseXMLContent(xmlContent: xmlContent, member: self)
        ifDebugPrint("\(organization.fullNameTown): completed refreshFirstImage() \(urlOfImageIndex.absoluteString)")
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
