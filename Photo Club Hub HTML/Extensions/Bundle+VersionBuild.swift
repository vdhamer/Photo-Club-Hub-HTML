//
//  Bundle+VersionBuild.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 05/08/2026.
//

import Foundation

extension Bundle {

    var shortVersion: String { // e.g. "2.12.3"
        if let result = infoDictionary?["CFBundleShortVersionString"] as? String {
            return result
        } else {
            assert(false)
            return "No version#"
        }
    }

    var buildVersion: String { // e.g. "1234"
        if let result = infoDictionary?["CFBundleVersion"] as? String {
            return result
        } else {
            assert(false)
            return "No build#"
        }
    }

    var fullVersion: String { // e.g. "2.12.3 (1234)"
        return "\(shortVersion) (\(buildVersion))"
    }
}
