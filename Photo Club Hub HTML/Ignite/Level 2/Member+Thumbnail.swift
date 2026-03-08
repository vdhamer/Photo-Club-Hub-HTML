//
//  Member+Thumbnail.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 27/02/2026.
//

import Foundation // for URL
import Photo_Club_Hub_Data // for ifDebugFatalError()
import CoreGraphics // for CGImage

extension Members {

    private static let maxFilenameSuffixNumber: Int = 50 // generates a warning in Debug version if count is suspicious

    func loadThumbnailToLocal(fullUrl: URL, dictionary: inout [String: String]) -> String {
        let newFileName = chooseLocalFileName(fullUrl: fullUrl, dictionary: &dictionary)
        downloadThumbnailToLocal(downloadURL: fullUrl, localFileName: newFileName)
        return newFileName
    }

    private func chooseLocalFileName(fullUrl: URL, dictionary: inout [String: String]) -> String {
        let fileExtension: String = fullUrl.pathExtension
        let baseFileName: String = fullUrl.deletingPathExtension().lastPathComponent
        let remoteURLString: String = fullUrl.absoluteString

        var count: Int = 1

        while true { // assumes we eventually find an unused filename

            if count > Members.maxFilenameSuffixNumber {
                // is while-loop getting suspicious?
                // only happens if club exceeds maxFilenameSuffixNumber members, and many of them use same filename
                ifDebugFatalError("Error: could not generate unique local image filename.")
            } // fatal error only occurs in Debug build

            let newFileName: String
            if count == 1 {
                newFileName = baseFileName + ".\(fileExtension)" // no need to change name
            } else {
                newFileName = baseFileName + "_\(count).\(fileExtension)"
            }

            if dictionary[newFileName] == nil { // haven't seen this filename variant yet for this club
                dictionary[newFileName] = remoteURLString
                return newFileName // newFileName hasn't been used before for this club
            } else {
                if dictionary[newFileName] == remoteURLString {
                    return newFileName
                } else {
                    count += 1
                    continue
                }
            }
        }

    }

    private func downloadThumbnailToLocal(downloadURL: URL, localFileName: String) { // for now this is synchronous

        do {
            // swiftlint:disable:next large_tuple
            var results: (data: Data?, urlResponse: URLResponse?, error: (any Error)?)? = (nil, nil, nil)
            results = URLSession.shared.synchronousDataTask(from: downloadURL)
            guard let data = results?.data else {
                fatalError("""
                       Problem downloading thumbnail \(downloadURL.absoluteString): \
                       \(results?.error?.localizedDescription ?? "")
                       """)
            }

            let image: CGImage = try CGImage.load(data: data) // SwiftImageReadWrite package
            let jpegData: Data  = try image.representation.jpeg(scale: 1, compression: 0.65, excludeGPSData: true)

            let buildDirectoryString = NSHomeDirectory() // app's home directory for a sandboxed MacOS app

            // some extra steps to ensure the Assets/images subdirectory exists
            let imagesDirectoryString = "file:\(buildDirectoryString)/Assets/images/"
            guard let imageDirUrl = URL(string: "\(imagesDirectoryString)") else {
                fatalError("Error creating URL for \(imagesDirectoryString)") }
            try FileManager.default.createDirectory(at: imageDirUrl, withIntermediateDirectories: true, attributes: nil)

            guard let imageUrl = URL(string: "\(imagesDirectoryString)\(localFileName)") else {
                fatalError("Error creating URL for \(imagesDirectoryString)\(localFileName)")
            }
            try jpegData.write(to: imageUrl)
            print("Wrote jpg to \(imageUrl)")
        } catch {
            ifDebugFatalError("Problem in downloadThumbNailToLocal(\(downloadURL.absoluteString)): \(error)")
            return
        }

    }

}
