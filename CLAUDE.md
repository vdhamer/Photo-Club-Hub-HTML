# Photo Club Hub HTML — Claude Code guidance

## What this project is

A macOS app that loads photo club membership data into CoreData and then generates a static website using the [Ignite](https://github.com/twostraws/Ignite) framework. The generated site has one page per photo club (planned: also one page per club/language combination), and one page per expertise/language combination.

## Repo relationships

This repo (`Photo Club Hub HTML`), the companion iOS app (`Photo Club Hub`) and the shared Swift Package (`Photo Club Hub Data`) are **three separate git repos**. The Data package was extracted from this repo in #232 and now lives at [vdhamer/Photo-Club-Hub-Data](https://github.com/vdhamer/Photo-Club-Hub-Data); this repo consumes it as a normal remote SwiftPM dependency, `.upToNextMinor(from: "2.11.3")` — deliberately narrow, so the requirement is bumped by hand each time the release train moves to a new minor. There is no `Photo Club Hub Data/` directory here any more, and no test target — the package's 86 tests run in the package repo's own CI.

The iOS app has since adopted the package (vdhamer/Photo-Club-Hub#769): its loaders and club `MembersProvider`s now come from the package rather than a duplicated copy. Unlike this repo, it consumes the package as a **local** path reference (`../Photo-Club-Hub-Data`) rather than a version tag — so package changes reach it immediately, including uncommitted ones, while this repo only sees them after a version bump and a resolve.

## Key dependencies

- **Ignite** — used as a **local fork** at `../../Ignite` (relative to the project root), not from upstream. Prefer fixing issues in this repo; only change the Ignite fork when the change serves as an intentional reminder of an upstream issue.
- **Photo Club Hub Data** — remote Swift Package containing the CoreData model, JSON loaders, and all club-specific `MembersProvider` files. It carries a build-tool plugin that compiles the `.xcdatamodeld`, so `xcodebuild` needs `-skipPackagePluginValidation` or it fails at "Validate plug-in". The Xcode GUI asks for plugin trust once instead. Edits to the package are made in its own repo and reach this one via a version bump.

## CoreData loading architecture

Data loads in three sequential levels:

- **Level 0** (`Level0JsonReader`): loads `Expertise` and `Language` records from `root.level0.json`. Must complete and **save** before Level 2 starts.
- **Level 1** (`Level1JsonReader`): loads `PhotoClub` / `Museum` records. May run concurrently with Level 2. The tree starts at `root_.level1.json` (with the underscore), which only pulls in `clubsNL` and `museums` via Includes — **not** `root.level1.json`, a legacy flat file that no current code path loads but that pre-2.9.0 app versions still fetch from GitHub. See the Data package's CLAUDE.md and vdhamer/Photo-Club-Hub#676.
- **Level 2** (one `MembersProvider` per club): loads member portfolios. Runs concurrently with other Level 2 loaders, but **only after Level 0 has saved**.

**The sequencing is not in this app.** It lives in `LevelLoader.loadAllLevels()` in the Photo Club Hub Data package ([Data#12](https://github.com/vdhamer/Photo-Club-Hub-Data/issues/12)), which awaits Level 0 to completion, then Level 1, then runs the 14 Level 2 club loaders in a task group, and returns only once the last one has finished. Both apps used to implement this themselves, with two different concurrency models and covered by neither app's tests; the package owns the model, so it owns the invariant.

What remains here is `PhotoClubHubHtmlApp.loadClubsAndMembers()`: configure the view context, wipe the database, then one call to `LevelLoader.loadAllLevels()`. Because that call returns only when the pass is complete, the Fill database menu item and any website generation after it see a complete database. Do not reintroduce a level-by-level sequence here — changing the order is a package change, with `LevelLoaderTest` asserting it.

**Why Level 0 must precede Level 2:** `Expertise` has a CoreData uniqueness constraint on `id_`. Level 0 creates expertises with `isSupported=true`; Level 2's `findCreateUpdateUndefSupported()` leaves new rows at the CoreData default `isSupported=false`. Two contexts inserting the same expertise never see each other's unsaved row, so the collision is settled by the merge policy and the flag can end up wrong.

Background contexts for loading are created by the package, which sets `mergeByPropertyStoreTrump` and `automaticallyMergesChangesFromParent = true` on them. This app no longer chooses — it previously used `mergeByPropertyObjectTrump` while the iOS app used StoreTrump, and neither app's choice was ever tested. The view context in this app still uses `mergeByPropertyObjectTrump`.

## Ignite gotchas

- **`.style()` API**: pass each CSS property as a separate argument. A string with semicolons (multiple properties) is silently ignored because Ignite splits on `:` and expects exactly 2 parts.
  - Wrong: `.style("display: flex; flex-direction: row")`
  - Right: `.style("display: flex", "flex-direction: row")`

## Sandboxed publish() prerequisites

Three things must be in place for `site.publish()` to work from the sandboxed app:

1. `Photo_Club_Hub_HTML.entitlements` needs `com.apple.security.app-sandbox = true` and `com.apple.security.network.client = true`.
2. `ClubListView.onAppear` must create the `NSHomeDirectory()/Assets` directory before `publish()` runs.
3. The Ignite fork's `PublishingContext.swift:copyResources()` has a defensive catch for `NSFileReadNoSuchFileError` on a missing Assets dir.

## Code style

- Prefer `let` over `var` wherever Swift allows it.
- No Combine — use Swift async/await for any new asynchronous work.
- The package's loader pipeline is internally closure-based (`bgContext.perform {}`); avoid refactoring that without coordinating with the iOS app. This app calls it through the readers' `async static load()` wrappers, which is the supported async entry point.
- Default to no comments; only add one when the WHY is non-obvious.

## Planning & process live in GitHub, not local files

GitHub is the technical and process source of truth across the Photo Club Hub repos
(Photo-Club-Hub, Photo-Club-Hub-Data, Photo-Club-Hub-HTML). Implementation plans, design
rationale, and follow-up work belong in **GitHub issues**, not in local `.md` files — the
maintainer and other contributors do not read local planning files.

- When you produce a plan or capture follow-up work, write it into the relevant GitHub issue
  (create one if needed) and make that issue self-sufficient: code sketches, file paths,
  decisions, and verification steps.
- Do not leave parallel local plan files; they go stale and nobody reads them.
- A short pointer in your own notes/memory is fine, but the content must live in GitHub.
