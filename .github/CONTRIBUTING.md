# Contributing to Photo-Club-Hub-HTML

Help is welcome. The guide for all four Photo Club Hub repositories is
[CONTRIBUTING.md in the Photo-Club-Hub repository](https://github.com/vdhamer/Photo-Club-Hub/blob/main/.github/CONTRIBUTING.md):
where to start, help that needs no code, and what a pull request needs.

What differs in this repository:

- Starter issues: [good first issue](https://github.com/vdhamer/Photo-Club-Hub-HTML/issues?q=is%3Aopen+label%3A%22Good+first+issue%22)
  and [help wanted](https://github.com/vdhamer/Photo-Club-Hub-HTML/issues?q=is%3Aopen+label%3A%22Help+wanted%22).
- This is a macOS app that generates the website with [Ignite](https://github.com/twostraws/Ignite).
  For now the project uses a fork, [vdhamer/Ignite](https://github.com/vdhamer/Ignite), as a local package
  at `../../Ignite`. Clone the fork there, two folders above this repository's folder, before opening the
  project; otherwise the build fails. The fork is based on an older Ignite version
  (see [#103](https://github.com/vdhamer/Photo-Club-Hub-HTML/issues/103)).
- Apart from that, building works as for the iOS app: open the `.xcodeproj`, select your own signing team,
  and run. See [Running the app](README.md#running-the-app) for what the app does once it runs.
