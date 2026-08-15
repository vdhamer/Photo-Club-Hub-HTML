//
//  PreferencesViewModelHTML.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 12/03/2026. Significant changes by Claude Code around 01/08/2026
//

import CoreData // for NSManagedObject
import Combine // for AnyCancellable

/// A view model that manages the user's preferences for generating HTML files.
///
/// `PreferencesViewModelHTML` is an `ObservableObject` that publishes a single `PreferencesStructHTML` value,
/// which contains all toggleable options.
///
/// The view model is annotated with `@MainActor` because it is observed by the UI
/// and its published state is read-only on the main thread.
///
/// Persistence
/// - The `preferences` property uses a custom `@Published("preferences", cancellableSet:)` wrapper
///   that persists changes and restores values across launches. The static `cancellableSet` is kept
///   on the type so the app can retain Combine subscriptions associated with persistence. (Hmmm. Written by ChapGTP).
///
/// Usage
/// - Observe an instance of this view model from SwiftUI views and bind to the `preferences` value.
/// - Read `preferences.memberPredicate` to obtain a composed `NSPredicate` that reflects the current
///   set of toggles (e.g., current members, officers, former members, etc.).
@MainActor
class PreferencesViewModelHTML: ObservableObject {
    /// Stores Combine cancellables tied to persistence of the `preferences` property.
    static var cancellableSet: Set<AnyCancellable> = []  // not used: view currently has no Candel button capabilities

    /// The app's persisted user preferences. Changes are published to update dependent views and
    /// are used to derive Core Data predicates for filtering content.
    @Published("preferences", cancellableSet: &cancellableSet)
    var preferences: PreferencesStructHTML = .defaultValue
}

struct PreferencesStructHTML: Sendable { // order in which they are shown on Preferences page
    var selectedClubNickname: String // if no club has ever been selected, we use "TemplateMin"
    var useLocalThumbnails: Bool
    var selectedHost: TargetHost
    var showFormerMembers: Bool
    var showFotobondMemberNumber: Bool
    var allowRemotePreview: Bool

    static let defaultValue = PreferencesStructHTML( // has to match order of declaration
        selectedClubNickname: "TemplateMin",
        useLocalThumbnails: false,
        selectedHost: TargetHost.localhost,
        showFormerMembers: false,
        showFotobondMemberNumber: isRunningInDutch, // Fotobond is a Dutch federation (defaults to off when != NL)
        allowRemotePreview: false // loopback-only preview until asked otherwise: see ``PreviewServer``
    )

    /// Whether the app's user interface is currently running in Dutch.
    ///
    /// `Bundle.main.preferredLocalizations.first` is the localization macOS actually picked for this app — the
    /// language the user is reading. `Locale.current` is the wrong question: it follows region and formatting
    /// preferences, and routinely disagrees. This app's own scheme is the example, launching with
    /// `-AppleLanguages (en)` alongside `-AppleLocale en_NL`.
    ///
    /// This only decides the *default*. Once the user sets the toggle either way, their choice is stored and
    /// wins from then on, whatever language the app runs in.
    static var isRunningInDutch: Bool {
        Bundle.main.preferredLocalizations.first?.hasPrefix("nl") ?? false
    }

}

extension PreferencesStructHTML: Codable {

    /// Decodes leniently: a key that an older stored copy lacks falls back to its default rather than failing
    /// the decode.
    ///
    /// This is not defensiveness for its own sake. `Published+UserDefaults` decodes with `try?` and falls back
    /// to ``defaultValue`` on *any* error, and Swift's synthesized decoding ignores a property's default value
    /// when the key is missing — so without this, adding one preference would silently reset every other one
    /// the first time the new build ran. Encoding stays synthesized.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = Self.defaultValue

        selectedClubNickname = try container.decodeIfPresent(String.self, forKey: .selectedClubNickname)
            ?? fallback.selectedClubNickname
        useLocalThumbnails = try container.decodeIfPresent(Bool.self, forKey: .useLocalThumbnails)
            ?? fallback.useLocalThumbnails
        selectedHost = try container.decodeIfPresent(TargetHost.self, forKey: .selectedHost)
            ?? fallback.selectedHost
        showFormerMembers = try container.decodeIfPresent(Bool.self, forKey: .showFormerMembers)
            ?? fallback.showFormerMembers
        showFotobondMemberNumber = try container.decodeIfPresent(Bool.self, forKey: .showFotobondMemberNumber)
            ?? fallback.showFotobondMemberNumber
        allowRemotePreview = try container.decodeIfPresent(Bool.self, forKey: .allowRemotePreview)
            ?? fallback.allowRemotePreview
    }
}
