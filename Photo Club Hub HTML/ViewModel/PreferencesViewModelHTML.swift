//
//  PreferencesViewModelHTML.swift
//  Photo Club Hub HTML
//
//  Created by Peter van den Hamer on 12/03/2026.
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

    static let defaultValue = PreferencesStructHTML( // has to match order of declaration
        selectedClubNickname: "TemplateMin",
        useLocalThumbnails: false,
        selectedHost: TargetHost.localhost,
        showFormerMembers: false,
        showFotobondMemberNumber: false
    )

}

extension String {
    func predicateOrAppend(suffix: String) -> String {
        guard self != "" else { return suffix }
        return self + " OR " + suffix
    }
}

extension PreferencesStructHTML: Codable {
//    No code needed as long as all preferences are Codable.
//    For trickier cases, check how it is done in Photo Club Hub's `PreferencesViewModel`
}
