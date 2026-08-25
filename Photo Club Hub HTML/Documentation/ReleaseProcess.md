## Release process

This app is released the same way the iOS app is, and that process is written down **once**, in the
iOS repo:

[`Photo Club Hub/Documentation/ReleaseProcess.md`](https://github.com/vdhamer/Photo-Club-Hub/blob/main/Photo%20Club%20Hub/Documentation/ReleaseProcess.md)

That document already covers this app by name: the steps of the release loop, the two-Mac split, the
numbering rules, the `b<number>` and `v<version>` tags, and what the archive gate refuses. None of it
is repeated here, because a second copy is a second thing to keep true.

What belongs to this repo rather than to the process:

| | |
| --- | --- |
| Platform | macOS. Same App Store Connect account, own app record, own bundle ID `com.vdHamer.Photo-Club-Hub-HTML` |
| Build numbers | start at 1000; the reasoning is in the *Version numbers* section of `CLAUDE.md` |
| Archive gate | `scripts/gate-and-stamp.sh`, byte-identical to the iOS copy — including the `b<number>` check. A [weekly sweep](https://github.com/vdhamer/Photo-Club-Hub-Data/blob/main/.github/workflows/weekly-sweep.yml) in Photo-Club-Hub-Data fails when the two drift |
| Release notes | `Photo Club Hub HTML/Documentation/ReleaseNotes.md` |
| Tag protection | `.github/rulesets/release-tags.json`, the local copy of this repo's `b*` / `v*` ruleset |

If the two processes ever genuinely diverge, add the difference to that table. 
Forking the document is what this file exists to prevent.
