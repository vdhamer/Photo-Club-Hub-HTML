TO-DO

* Update ReleaseNotes to 3.0.0

---------------------------------------------------------------------------

### 3.0.0 (GitHub commit ???????) ??-??-2026

USER-FACING

* The Country column of the club table now reads "Country?" for an organization whose address has not been reverse-geocoded yet, where it was previously blank. Those rows still sort to the top rather than among the C's, so they stay visible as a group: the displayed string and the sort key are deliberately different questions (Photo-Club-Hub#827).
* The generated site is published into a `/hub` subdirectory of the selected host instead of at its root, so a page moves from `<host>/nl/clubs` to `<host>/hub/nl/clubs`. This matters because the published hosts serve this app's output from inside a site that is not ours: at the root, this site's `index.html`, `robots.txt`, `sitemap.xml` and `favicon.png` land beside the host site's own, and `index.html` wins over `index.php` under the usual `DirectoryIndex` order, so publishing would have replaced the home page of the site hosting us. Previewing is unaffected, because `TargetHost.url(forPath:)` deliberately ignores the path for `.localhost`, whose document root is the generated site itself. Note that the subdirectory name is part of every published URL, including any that have been printed (HTML#260). First published this way on 8 September 2026, to `www.fcdegender.nl/hub`; the previously published `/clubs`, `/expertises`, `/fgDeGender` and `/fgWaalre` paths now redirect there with a 301.
* The generated `sitemap.xml` is now well-formed XML, so search engines can read it. A path holding a literal `&` was written into `<loc>` unescaped, and there is exactly one such path: the expertise whose canonical `idString` is `Black & white`. Because a crawler accepts or rejects a sitemap as a whole rather than skipping the offending entry, that single character cost the site all 105 of its entries, and had done so for as long as the file has been generated (HTML#260 found it while checking a publish).

* Members with no portfolio photo now show a placeholder that a browser will actually load. The Data package returned an `http://`-only URL for them, which browsers drop on a site served over https (vdhamer/Photo-Club-Hub-Data#52, HTML#264). The image is square now as well, so the 1:1 cell no longer crops and upscales it.

STRUCTURAL

* The Country and Town cells read `Organization.localizedCountry(for:)` and `localizedTown(for:)` instead of reaching past them to the underscored `localizedCountry_` / `localizedTown_`. The fallback for a missing `LocalizedAddress` row now lives in the package, shared with the iOS app, rather than being spelled out at each call site. The Town cell keeps its own diacritic handling, which applies to the JSON-supplied name but deliberately not to a geocoded one, so it still tests for the row rather than reading through the accessor alone.
* The sitemap fix lives in the **Ignite fork** (`Sources/Ignite/Publishing/SiteMapGenerator.swift`), not in this repo, because the file is produced entirely inside Ignite with no seam this app could override. It escapes `&`, `<` and `>` before interpolation rather than percent-encoding the path, deliberately: `&` is legal in a URL path segment (RFC 3986 sub-delims), so the generated links were always correct and only the XML was wrong — escaping leaves every link byte-identical. A regression test came with it (`Tests/IgniteTests/SiteMapGeneratorTests.swift`), asserting that the output *parses* as XML rather than merely containing the right substring. **The bug is still present in upstream Ignite as of September 2026**, so an Ignite update has to carry this change forward rather than assume it arrived; the fork's own comment says so at the call site.
* Built using v3.3.0 of the Photo Club Hub Data package.

KNOWN ISSUES

* The navigation bar's *Stats* item links to `/<lang>/statistics`, a page the generator does not build, so it is a 404 on every generated page. A deliberate placeholder from before the site was published (HTML#263).

DOCUMENTATION

* `Level0Pages.swift`: the comment giving the published location of the expertises pages now says `/hub/nl/expertises` instead of the pre-migration path.

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
