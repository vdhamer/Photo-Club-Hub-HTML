//
//  ThumbnailDownloader.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 30/05/2026.
//

import Foundation // for URL, URLSession, Data, FileManager, NSHomeDirectory, NSLock
import CoreGraphics // for CGImage
import Photo_Club_Hub_Data // for ifDebugFatalError()
import SwiftImageReadWrite // for CGImage.load() and image format conversion

// For now, tahis is only a public function, with private utility functions and private data.
// It _could_ be turned into an Actor, thereby modifying the serialization/concurrency approach.

// When `preferences.useLocalThumbnails` is __enabled__, thumbnail images are downloaded from their remote URLs,
// converted to JPEG with a quality/size tradeoff, and stored locally in `Assets/images/` before HTML generation starts.
// The generated HTML then references these local copies instead of the original remote URLs.

// When `preferences.useLocalThumbnails` is __disabled__, the generated HTML references the remote URLs directly.

// Note that this file looks unrelated to the Ignite framework, but it does put
// the local files in a directory path where Ignite Images expect to find them.

// The maximum number of remote files with the same filename (and different paths) is limited only in the DEBUG version.
private let maxFilenameSuffixNumber: Int = 100 // generates a fatalerror in Debug mode. Investigate any high count.

// Shared registry mapping local filenames to the remote URLs they hold.
// Shared across all page types (Level0, Level2, etc.) because they all write to the same Assets/images/ directory.
// This ensures globally unique local filenames when different remote paths have the same base filename.
private let registryLock = NSLock() // protects localNameRegistry and downloadURLs from race conditions
nonisolated(unsafe) private var localNameRegistry: [String: String] = [:] // [local filename: remote file path]
nonisolated(unsafe) private var downloadedURLs: Set<String> = [] // saves all handled remote file paths

func loadThumbnailToLocal(fullUrl: URL) -> String {
    // Lock only for the filename reservation; the downloading is not protected from early browser opening of FTPing.
    var shouldDownload = false
    let chosenLocalFileName: String = registryLock.withLock {
        let filename = chooseLocalFileName(fullUrl: fullUrl)
        if downloadedURLs.insert(fullUrl.absoluteString).inserted {
            shouldDownload = true // first time we've seen this URL; download needed
        }
        return filename
    }
    // Currently (1-Jun-2026) there is no guarantee that the download finishes before testing or use (issue #203).
    if shouldDownload { // prevent multiple downloads from same fullUrl
        downloadThumbnailToLocal(downloadURL: fullUrl, localFileName: chosenLocalFileName)
    }
    return chosenLocalFileName
}

private func chooseLocalFileName(fullUrl: URL) -> String {
    let fileExtension: String = fullUrl.pathExtension
    let baseFileName: String = fullUrl.deletingPathExtension().lastPathComponent
    let remoteURLString: String = fullUrl.absoluteString

    var count: Int = 1 // the next candidate suffix that might be used

    while true { // scan incrementing series of numeric suffices until we find find a new filename

        if count > maxFilenameSuffixNumber {
            // happens if photographer reused the name, club members reused the name, or clubs reused the name
            ifDebugFatalError("Error: could not generate unique local image filename.") // only in Debug builds
            return baseFileName + ".\(fileExtension)" // just keep incrementing in Release builds
        }

        let newFileName: String
        if count == 1 {
            newFileName = baseFileName + ".\(fileExtension)" // don't add a suffix until that is really required
        } else {
            newFileName = baseFileName + "_\(count).\(fileExtension)"
        }

        if localNameRegistry[newFileName] == nil { // haven't seen this filename[suffix] variant yet
            localNameRegistry[newFileName] = remoteURLString
            return newFileName // newFileName hasn't been used before
        } else {
            if localNameRegistry[newFileName] == remoteURLString {
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
        let jpegData: Data = try image.representation.jpeg(scale: 1, compression: 0.65, excludeGPSData: true)

        let buildDirectoryString = NSHomeDirectory() // app's home directory for a normal sandboxed MacOS app

        // some extra steps to ensure the Assets/images subdirectory exists
        let imageDirUrl = URL(fileURLWithPath: buildDirectoryString)
            .appendingPathComponent("Assets/images", isDirectory: true)
        try FileManager.default.createDirectory(at: imageDirUrl,
                                                withIntermediateDirectories: true, // prevents throwing error if exists
                                                attributes: nil)

        let imageUrl = imageDirUrl.appendingPathComponent(localFileName)
        try jpegData.write(to: imageUrl)
        print("Wrote jpg to \(imageUrl)")
    } catch {
        ifDebugFatalError("Problem in jpegData.write in downloadThumbnailToLocal for " +
                          "(\(downloadURL.absoluteString)): \(error)")
        return
    }

}
