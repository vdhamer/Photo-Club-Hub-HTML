TO-DO

* Update ReleaseNotes to 3.0.0

---------------------------------------------------------------------------

### 3.0.0 (GitHub commit ???????) ??-??-2026

USER-FACING

* The Country column of the club table now reads "Country?" for an organization whose address has not been reverse-geocoded yet, where it was previously blank. Those rows still sort to the top rather than among the C's, so they stay visible as a group: the displayed string and the sort key are deliberately different questions (Photo-Club-Hub#827).

STRUCTURAL

* The Country and Town cells read `Organization.localizedCountry(for:)` and `localizedTown(for:)` instead of reaching past them to the underscored `localizedCountry_` / `localizedTown_`. The fallback for a missing `LocalizedAddress` row now lives in the package, shared with the iOS app, rather than being spelled out at each call site. The Town cell keeps its own diacritic handling, which applies to the JSON-supplied name but deliberately not to a geocoded one, so it still tests for the row rather than reading through the accessor alone.
* Built using v3.2.0 of the Photo Club Hub Data package.

---------------------------------------------------------------------------

### 2.11.3 (GitHub commit ecf3d67) 07-08-2026

USER-FACING

* Filling the database — at launch and via the Actions → Fill database menu item — now shows a progress spinner, and finishes only once every club has finished loading. Previously the loaders were fire-and-forget, so there was no moment at which the load was known to be complete.
- About - app now has an About window showing versioning information.

STRUCTURAL

* Level 0 → Level 1 → Level 2 sequencing moved from `DispatchGroup` plus `notify(queue: .main)` to async/await, so the app stopped using a second concurrency model alongside the iOS app's.
* All fourteen club loaders now call their awaitable `static load()` rather than the fire-and-forget initializers.
* The sequencing then moved out of this app entirely: `loadClubsAndMembers()` is now a call to `LevelLoader.loadAllLevels()` (Data#12). `loadLevels0To2()`, the fourteen-club list and this app's `makeBgContext` are gone — 136 fewer lines in `Photo_Club_Hub_HTMLApp.swift`. The background contexts' merge policy is now the package's choice rather than this app's, which ends a silent disagreement with the iOS app about it.
* Built using v2.11.4 of the Photo Club Hub Data package.

DOCUMENTATION

* CLAUDE.md: the "CoreData loading architecture" section describes the async/await sequencing rather than the `DispatchGroup`.
* Release notes for the HTML app created.

---------------------------------------------------------------------------

Releases before 2.11.3 predate this file. See the git tags and their GitHub release descriptions.
