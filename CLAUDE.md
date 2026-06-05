# Photo Club Hub HTML — Claude Code guidance

## What this project is

A macOS app that loads photo club membership data into CoreData and then generates a static website using the [Ignite](https://github.com/twostraws/Ignite) framework. The generated site has one page per photo club (planned: also one page per club/language combination), and one page per expertise/language combination.

## Repo relationships

This repo (`Photo Club Hub HTML`) and the companion iOS app (`Photo Club Hub`) are **two separate git repos** that share a single Swift Package called `Photo Club Hub Data`. The Data package currently lives inside this repo at `Photo Club Hub Data/` and is embedded directly in the Xcode project. It is planned to become a standalone GitHub repo that both apps depend on, and will eventually replace a large portion of the existing Photo Club Hub (iOS) repo's own code. Until that migration happens, changes to the Data package must remain compatible with the iOS app as it stands today.

## Key dependencies

- **Ignite** — used as a **local fork** at `../../Ignite` (relative to the project root), not from upstream. Prefer fixing issues in this repo; only change the Ignite fork when the change serves as an intentional reminder of an upstream issue.
- **Photo Club Hub Data** — the embedded Swift Package containing CoreData model, JSON loaders, and all club-specific `MembersProvider` files.

## CoreData loading architecture

Data loads in three sequential levels:

- **Level 0** (`Level0JsonReader`): loads `Expertise` and `Language` records from `root.level0.json`. Must complete and **save** before Level 2 starts.
- **Level 1** (`Level1JsonReader`): loads `PhotoClub` / `Museum` records. Runs concurrently with Level 2.
- **Level 2** (one `MembersProvider` per club): loads member portfolios. Runs concurrently with other Level 2 loaders, but **only after Level 0 has saved**.

The sequencing is enforced in `Photo_Club_Hub_HTMLApp.swift` using a `DispatchGroup` on the Level 0 background context's serial queue. Level 1 and Level 2 start together from `level0Group.notify(queue: .main)`.

**Why Level 0 must precede Level 2:** `Expertise` has a CoreData uniqueness constraint on `id_`. Level 0 creates expertises with `isSupported=true`; Level 2's `findCreateUpdateUndefSupported()` creates them with the CoreData default `isSupported=false`. With `mergeByPropertyObjectTrump`, whichever context saves second wins per property — so concurrent saves corrupt the `isSupported` flag.

All background contexts use:
- `mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump`
- `automaticallyMergesChangesFromParent = true`

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
- The existing loader pipeline uses `bgContext.perform {}` (closure-based, not async); avoid refactoring it without coordinating with the iOS app.
- Default to no comments; only add one when the WHY is non-obvious.
