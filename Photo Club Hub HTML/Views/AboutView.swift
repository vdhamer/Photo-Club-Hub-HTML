//
//  AboutView.swift
//  Photo Club Hub HTML
//
//  Created by Claude Code guided by Peter van den Hamer on 05/08/2026.
//

import SwiftUI
import AppKit // for NSApplication.applicationIconImage and NSPasteboard

struct AboutView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var copied = false

    private let repositoryURL = URL(string: "https://github.com/vdhamer/Photo-Club-Hub-HTML")!

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) { // icon and app name
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 50, height: 50)

                appName
                    .font(.title2)
                    .bold()
            }

            VStack(alignment: .leading, spacing: 6) {
                // Two named groups side-by-side.
                // The left/leading one is about the app.
                // The right/trailing one is about the Photo Club Hub Data package.
                // The extra width this costs is needed anyway to display paths (a bit further down).
                HStack(alignment: .top, spacing: 24) {
                    labeledGroup(appName) {
                        versionRow(versionLabel, value: Bundle.main.fullVersion,
                                   missing: noStamp, isIdentifier: true)
                        versionRow(commitLabel, value: Bundle.main.gitCommit,
                                   missing: noStamp, isIdentifier: true)
                        versionRow(Text("Built", tableName: "PhotoClubHubHTML.SwiftUI",
                                        comment: "Label for the date and time this app was built"),
                                   value: Bundle.main.buildDate, missing: noStamp)
                    }

                    labeledGroup(dataPackageName) {
                        versionRow(versionLabel, value: Bundle.main.libraryVersion,
                                   missing: noStamp, isIdentifier: true)
                        versionRow(commitLabel, value: Bundle.main.libraryCommit,
                                   missing: notApplicable, isIdentifier: true)
                        versionRow(Text("Committed", tableName: "PhotoClubHubHTML.SwiftUI",
                                        comment: "Label for when the Data package's commit was made"),
                                   value: Bundle.main.libraryCommitDate, missing: notApplicable)
                    }
                }

                labeledGroup(Text("Paths", tableName: "PhotoClubHubHTML.SwiftUI",
                                   comment: "Header over the repository link and the output folder")) {
                    HStack {
                        Text("GitHub", tableName: "PhotoClubHubHTML.SwiftUI",
                             comment: "Label for the link to this app's source code repository")
                        Spacer()
                        Link(destination: repositoryURL) {
                            Text(verbatim: "vdhamer/Photo-Club-Hub-HTML")
                                .foregroundStyle(.link)
                        }
                    }
                    .padding(.leading, 8)

                    HStack {
                        Text("Output folder", tableName: "PhotoClubHubHTML.SwiftUI",
                             comment: "Label for the folder that the generated website is written to")
                        Spacer()
                        Button {
                            SiteOutput.revealInFinder()
                        } label: {
                            Text(verbatim: shortOutputPath)
                                .foregroundStyle(.link)
                        }
                        .buttonStyle(.plain)
                        .help(outputPath) // the tooltip carries what the row leaves out
                    }
                    .padding(.leading, 8)
                }
                .padding(.top, 18)
            }

            // Copy button sits on the leading edge and Close on the trailing one:
            // Close is what dismisses the window,
            // Copy dumps the data to the macOS clipboard (just a nice to have).
            // Button widths wide enough for the longest label in either
            // language, so the Copy button does not resize when it flips to "Copied".
            HStack {
                copyButton
                Spacer()
                closeButton
            }
        }
        .padding(24)
        .frame(width: 540)
    }

    // The app's own name, localized: the same string the window title uses, so the column header and
    // the title cannot drift apart. The other column names its subject too, which is what makes the
    // two headers read as a pair.
    private var appName: Text {
        Text("Photo Club Hub HTML", tableName: "PhotoClubHubHTML.SwiftUI", comment: "Name of this macOS app")
    }

    // Localized alongside the app's own name: "Photo Club Hub" is "Fotoclub Hub" throughout the Dutch
    // interface, and a Dutch reader who sees "Fotoclub" everywhere else should not meet "Photo Club"
    // here. It is the package's product name, so only the "Photo Club Hub" part is translated.
    private var dataPackageName: Text {
        Text("Photo Club Hub Data", tableName: "PhotoClubHubHTML.SwiftUI",
             comment: "Name of the Data package this app is built against")
    }

    // Not tilde-abbreviated: in a sandboxed app NSHomeDirectory() *is* the container, so "~" would
    // collapse the whole path and then mean something else in Finder or Terminal.
    private var outputPath: String {
        SiteOutput.buildDirectory.path(percentEncoded: false)
    }

    /// The output folder shortened for display, e.g. `…/com.vdHamer.Photo-Club-Hub-HTML/Data/Build`.
    ///
    /// The full path runs to some 80 characters: beside its label it does not fit at a readable size,
    /// and at a size where it fits it cannot be read. Only the tail identifies the folder — the head
    /// is the same sandbox container prefix on every Mac — so the tail is what the row shows. The
    /// whole path stays one click away in Finder, sits in the tooltip, and is what the Copy button
    /// puts on the clipboard.
    private var shortOutputPath: String {
        let components = SiteOutput.buildDirectory.pathComponents.filter { $0 != "/" }
        guard components.count > 3 else { return outputPath }
        return "…/" + components.suffix(3).joined(separator: "/")
    }

    // Every label here is a `Text` built from a literal at the point of use, not a `String` from
    // `String(localized:)`. Both localize, but only the `Text` form resolves through the SwiftUI
    // environment, and the rows that used the `String` form showed up as untranslated (and, with the
    // scheme's "Show non-localized strings" on, in capitals) while every neighboring row did not.
    private var noStamp: Text {
        Text("?", tableName: "PhotoClubHubHTML.SwiftUI",
             comment: "Stands in for the build date or commit when absent")
    }

    // "N/A" rather than "?": a local checkout or an unreadable pin means there is no commit to name,
    // which is a different thing from a stamp having gone missing.
    private var notApplicable: Text {
        Text("N/A", tableName: "PhotoClubHubHTML.SwiftUI",
             comment: "Stands in for the library commit when there is none to show")
    }

    // Both version groups ask the same two questions, so both use the same two labels.
    private var versionLabel: Text {
        Text("Version", tableName: "PhotoClubHubHTML.SwiftUI",
             comment: "Label for a version number, used for this app and for the Data package")
    }

    private var commitLabel: Text {
        Text("Commit", tableName: "PhotoClubHubHTML.SwiftUI",
             comment: "Label for a git commit, used for this app and for the Data package")
    }

    //
    private func labeledGroup<Rows: View>(_ header: Text, @ViewBuilder rows: () -> Rows) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader(header)
            rows()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Gray rather than black, and a size up from the rows: a header that is quieter in color but
    // larger in size reads as a heading without competing with the values it introduces.
    private func sectionHeader(_ title: Text) -> some View {
        title
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.bottom, 2)
    }

    /// One label-and-value row. `isIdentifier` marks values that are read character by character
    /// rather than as words — version numbers and commit hashes — and sets them in a monospaced face,
    /// which lines their digits up and tells the eye it may skip them. Dates and names stay in the
    /// body font: they are meant to be read.
    private func versionRow(_ title: Text, value: String?, missing: Text,
                            isIdentifier: Bool = false) -> some View {
        HStack {
            title
            Spacer()
            (value.map { Text(verbatim: $0).monospaced(isIdentifier) } ?? missing)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 8) // nests the rows under the header they belong to
    }

    /// Everything the window shows, as plain text, for pasting into an issue.
    ///
    /// Deliberately English and unlocalized: the destination is a bug report, not the screen. The
    /// dates are the formatted ones on display, which is a small locale dependency accepted so that
    /// what is pasted matches what was read. The output folder goes in whole, unlike the row.
    private var aboutInfoForClipboard: String {
        """
        Photo Club Hub HTML \(Bundle.main.fullVersion), \
        commit \(Bundle.main.gitCommit ?? "unknown"), built \(Bundle.main.buildDate ?? "unknown")
        Photo Club Hub Data \(Bundle.main.libraryVersion ?? "unknown"), \
        commit \(Bundle.main.libraryCommit ?? "n/a"), committed \(Bundle.main.libraryCommitDate ?? "n/a")
        GitHub \(repositoryURL.absoluteString)
        Output folder \(outputPath)
        """
    }

    private var closeButton: some View {
        Button {
            dismissWindow()
        } label: {
            Text("Close",
                 tableName: "PhotoClubHubHTML.SwiftUI",
                 comment: "Button to close the About window")
                .frame(minWidth: buttonWidth, minHeight: 20)
        }
        .keyboardShortcut(.cancelAction)
        .buttonStyle(.automatic)
    }

    // No icon on Close: macOS dialog buttons are labeled in words, and there is no conventional
    // glyph for dismissing a window the way there is for copying to the clipboard.
    private var buttonWidth: CGFloat { 96 }

    // Somewhat fancy behavior: after Copy is used, it changes for 1.5 second to "Copied" as feedback
    private var copyButton: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(aboutInfoForClipboard, forType: .string)
            copied = true
            Task { // the copy is instant; the changed label is the only confirmation there is
                try? await Task.sleep(for: .seconds(1.5))
                copied = false
            }
        } label: {
            Group {
                if copied {
                    Label { Text("Copied",
                                 tableName: "PhotoClubHubHTML.SwiftUI",
                                 comment: "Button label right after the About information was copied") }
                    icon: { Image(systemName: "checkmark") }
                } else {
                    Label { Text("Copy",
                                 tableName: "PhotoClubHubHTML.SwiftUI",
                                 comment: "Button that copies everything this window shows to the clipboard") }
                    icon: { Image(systemName: "document.on.document") }
                }
            }
            .frame(minWidth: buttonWidth, minHeight: 20) // minHeight prevents minor jiggle during `copied == false`
        }
        .buttonStyle(.glass)
    }
}

// Believe it or not, this preview actually works

#Preview {
    AboutView()
}
