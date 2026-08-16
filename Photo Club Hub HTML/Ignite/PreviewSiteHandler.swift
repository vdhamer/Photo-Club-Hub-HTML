//
//  PreviewSiteHandler.swift
//  Photo Club Hub HTML
//
//  Created by Claude Code under supervision of Peter van den Hamer on 13/08/2026.
//

import Foundation // for URL, FileManager
import FlyingFox // for HTTPHandler, HTTPRequest, HTTPResponse, FileHTTPHandler
import UniformTypeIdentifiers // for UTType

/// Maps a request path onto a file inside the generated site, and hands the file to FlyingFox (#249).
///
/// FlyingFox ships `DirectoryHTTPHandler`, but it is not usable here: it appends the request path to the
/// root and serves whatever file that names, without ever resolving a directory URL to its `index.html`.
/// That is what matters for this site, where `/en/clubs/` is a directory URL, so path resolution stays in
/// this repo.
///
/// Dot segments are *not* the reason. FlyingFox standardizes those away in `HTTPDecoder` before any handler
/// runs — the fix for swhitty/FlyingFox#24 — so `..` never reaches ``resolve(_:)``. What the decoder cannot
/// do is resolve symlinks, because only this handler knows the root they would have to stay under. That is
/// what the containment check in ``resolve(_:)`` is for, with dot segments covered again as defence in depth.
///
/// Everything after resolution is FlyingFox's: file streaming, `Content-Length`, `ETag`/`Last-Modified`
/// with 304 handling, and HTTP/1.1 persistent connections. That last one is not a refinement — it is why
/// `ignite run --preview` is not used here at all. It serves via `python3 -m http.server`, which speaks
/// HTTP/1.0 and closes the connection after every response; Safari then reuses a pooled connection the
/// server has already closed, gets 0 bytes back, and stalls ~29 s before retrying.
struct PreviewSiteHandler: HTTPHandler {

    /// The directory to serve. Paths are resolved against it per request, never cached: a *Generate*
    /// deletes and recreates `Build/`, and the server has to survive that.
    let root: URL

    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard request.method == .GET || request.method == .HEAD else {
            // FlyingFox predefines the common headers but not Allow, hence the string. The annotation
            // matters: an unannotated literal is a plain Dictionary, which picks a deprecated overload.
            let headers: HTTPHeaders = [HTTPHeader("Allow"): "GET, HEAD"]
            return HTTPResponse(statusCode: .methodNotAllowed, headers: headers)
        }
        guard let fileURL = resolve(request.path) else {
            return HTTPResponse(statusCode: .notFound)
        }

        // `no-store` rather than FlyingFox's default `private`: a regenerate must be visible on the next
        // reload instead of being masked by the browser's heuristic freshness.
        return try await FileHTTPHandler(path: fileURL,
                                         contentType: Self.contentType(of: fileURL),
                                         cacheControl: [.noStore])
            .handleRequest(request)
    }

    /// Maps a request path onto a file inside ``root``, or nil when it escapes or doesn't exist.
    ///
    /// Directory URLs resolve to their `index.html`, which is what makes `/en/clubs/` work.
    private func resolve(_ path: String) -> URL? {
        let decoded = path.removingPercentEncoding ?? path
        let relative = decoded.split(separator: "/").joined(separator: "/")

        let base = root.resolvingSymlinksInPath()
        let candidate = base.appending(path: relative).standardizedFileURL.resolvingSymlinksInPath()

        // Containment check: with symlinks and any dot segments resolved, the result must still sit under
        // root. A symlink pointing out of Build/ is the case FlyingFox's own decoder cannot catch.
        let basePath = base.path(percentEncoded: false)
        let candidatePath = candidate.path(percentEncoded: false)
        guard candidatePath == basePath || candidatePath.hasPrefix(basePath + "/") else { return nil }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: candidatePath, isDirectory: &isDirectory) else { return nil }
        if isDirectory.boolValue {
            let index = candidate.appending(path: "index.html")
            return FileManager.default.fileExists(atPath: index.path(percentEncoded: false)) ? index : nil
        }
        return candidate
    }

    /// FlyingFox has its own MIME lookup, but keeps it internal, so this stays here.
    private static func contentType(of url: URL) -> String {
        // Ignite emits .rss and .xml, which UTType maps to text/xml and application/xml respectively;
        // both are fine for a browser. Anything unrecognised falls back to a byte stream.
        guard let type = UTType(filenameExtension: url.pathExtension),
              let mime = type.preferredMIMEType else { return "application/octet-stream" }
        return type.conforms(to: .text) || type == .html ? "\(mime); charset=utf-8" : mime
    }

}
