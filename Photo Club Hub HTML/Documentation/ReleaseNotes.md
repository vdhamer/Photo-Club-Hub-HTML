TO-DO

* Update ReleaseNotes to 3.0.0

---------------------------------------------------------------------------

### 2.11.3 (GitHub commit ecf3d67) 07-08-2026

USER-FACING

* Filling the database — at launch and via the Actions → Fill database menu item — now shows a progress spinner, and finishes only once every club has finished loading. Previously the loaders were fire-and-forget, so there was no moment at which the load was known to be complete.
- About - app now has an About window showing versioning information.

STRUCTURAL

* Level 0 → Level 1 → Level 2 sequencing moved from `DispatchGroup` plus `notify(queue: .main)` to async/await, so the app stopped using a second concurrency model alongside the iOS app's.
* All fourteen club loaders now call their awaitable `static load()` rather than the fire-and-forget initialisers.
* The sequencing then moved out of this app entirely: `loadClubsAndMembers()` is now a call to `LevelLoader.loadAllLevels()` (Data#12). `loadLevels0To2()`, the fourteen-club list and this app's `makeBgContext` are gone — 136 fewer lines in `Photo_Club_Hub_HTMLApp.swift`. The background contexts' merge policy is now the package's choice rather than this app's, which ends a silent disagreement with the iOS app about it.
* Built using v2.11.4 of the Photo Club Hub Data package.

DOCUMENTATION

* CLAUDE.md: the "CoreData loading architecture" section describes the async/await sequencing rather than the `DispatchGroup`.
* Release notes for the HTML app created.

---------------------------------------------------------------------------

Releases before 2.11.3 predate this file. See the git tags and their GitHub release descriptions.
