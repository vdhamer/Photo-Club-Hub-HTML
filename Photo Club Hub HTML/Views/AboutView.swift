//
//  AboutView.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 05/08/2026.
//

import SwiftUI
import AppKit // for NSApplication.applicationIconImage
import Photo_Club_Hub_Data // for PhotoClubHubDataVersion

struct AboutView: View {
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)

                Text("Photo Club Hub HTML",
                     tableName: "PhotoClubHubHTML.SwiftUI",
                     comment: "Name of this macOS app")
                .font(.title2)
                .bold()
            }

            VStack(alignment: .leading, spacing: 6) {
                versionRow(title: String(localized: "HTML app version",
                                         table: "PhotoClubHubHTML.SwiftUI",
                                         comment: "Label for this app's own marketing version and build number"),
                           value: Bundle.main.fullVersion)
                versionRow(title: String(localized: "Library version",
                                         table: "PhotoClubHubHTML.SwiftUI",
                                         comment: "Label for the Photo Club Hub Data package's version"),
                           value: "\(PhotoClubHubDataVersion.semver) (N/A)")
                HStack {
                    Text(verbatim: "Github")
                    Spacer()
                    Link(destination: URL(string: "https://github.com/vdhamer/Photo-Club-Hub-HTML")!) {
                        Text(verbatim: "vdhamer/Photo-Club-Hub-HTML")
                            .foregroundStyle(.link)
                    }
                }
                HStack {
                    Text(verbatim: "Repository owner")
                    Spacer()
                    Text(verbatim: "Peter van den Hamer")
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Spacer()
                Button {
                    dismissWindow()
                } label: {
                    Text("Close", tableName: "PhotoClubHubHTML.SwiftUI", comment: "Button to close the About window")
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 320)
    }

    private func versionRow(title: String, value: String) -> some View {
        HStack {
            Text(verbatim: title)
            Spacer()
            Text(verbatim: value)
                .foregroundStyle(.secondary)
        }
    }
}

// This preview actually works
#Preview {
    AboutView()
}
