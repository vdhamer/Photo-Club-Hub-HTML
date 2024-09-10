<div id="top"></div>

[![Version][stable-version]][version-url]
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![Discussions][discussions-shield]][discussions-url]
[![MIT License][license-shield]][license-url]

![Sample output website](images/Screenshot_Ignite.png "Sample output website")

# Photo-Club-Hub-HTML

This MacOS app is a companion to the iOS app vdhamer/Photo-Club-Hub.
It generates static HTML websites using [twostraws/ignite](https://github.com/twostraws/ignite).
The target domain is photo clubs that want to show curated work by their members online.

This data forms a hierarchy with three levels: 

1. central root list of (dozens/hundreds/thousands of) participating clubs,
2. local lists with (dozens of) members per club), and
3. local portfolios with the actual (dozens of) selected images per member.

> The idea is to provide a centralized access to view images that are managed by the various clubs.
 
This concept is comparable to a mini version of the hierarchy of distributed
[Domain Name System](https://en.wikipedia.org/wiki/Domain_Name_System) servers that translate addresses on the Internet: 
the app has one `root.level1.json` entry point that leads it to clubs which have `level2.json` membership lists under their 
own control that in turn point to the actual portfolios which can be managed by the club or by the individual photographers.

This MacOS app will at some point use the `root.level1.json` file to find a relevant `club.level2.json` file,
and convert the latter into a static website.
That website (or subsite) provides an alternative to the iOS app for users on other platforms.
SwiftUI is used for the user interface: end users will only reequire minimal software skills.
CoreData is used as a cache to ensure that the UI displays data immediately without having to wait for background updates.

## Comparison to iOS app

TODO: add side-to-side comparison screenshots.

| Variant  | iOS App  | Website |
| ----------- | ----------- | ------- |
| Runs on       | iOS, iPadOS, (MacOS) | all major browsers |
| List of clubs | yes       | not yet        |
| List of club members | yes | yes |
| Member portfolios | yes | yes |
| Portfolio autoplay | yes | yes |
| Content updates | when club updates its data | when club updates its data |
| Maps showing clubs | yes | no |
| Photo musea | yes | not yet |
| Search | yes | no |

## Static sites and Ignite

This app runs on MacOS because it generates a directory with a few files and subdirectories (CSS, Javascript, image assets).
These are generated on a Mac and then copied over to a club's server via e.g. FTP or maybe a Wordpress plug-in.

The data being displayed on the individual HTML sites may get updated 5-20 times per year.
Because the update frequency is relatively low, and because the owners of the data are assumed to have limited "computer" expertise,
it is best to generate static web sites. 
This limits the technical hasstle to uploading a file to a directory and associated useername/password.
This should be a lot easier and more robust than having a backend that dynamically generates a site on demand.

**Ignite** allows developers to write a fixed tool in Swift 
that defines the content of the static website without having to code HTML/CSS/Javascript.
It just generates these from a declarative higher-level description that resembles data more than it resembles code..

## Roadmap

- [ ] Fix the code (requested help from the team behind twostraws/Ignite) so that the rendering works.
- [ ] Load the membership list from a .level2.json file. Currently the app contains a copy of some of the data.
- [ ] provide a UI by which the user can select a club for which to generate a local site.
- [ ] localize the UI to support English (EN) and Dutch (NL),
- [ ] possibly generate a static site that can serve as index of supported clubs.
- [ ] possibly create one or more editor apps for managing the content in the JSON files

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[stable-version]: https://img.shields.io/github/v/release/vdhamer/Photo-Club-Hub-HTML?style=plastic&color=violet
[version-url]: https://github.com/vdhamer/Photo-Club-Hub-HTML/releases

[contributors-shield]: https://img.shields.io/github/contributors/vdhamer/Photo-Club-Hub-HTML?style=plastic
[contributors-url]: https://github.com/vdhamer/Photo-Club-Hub-HTML/graphs/contributors

[forks-shield]: https://img.shields.io/github/forks/vdhamer/Photo-Club-Hub-HTML?style=plastic&color=teal
[forks-url]: https://github.com/vdhamer/Photo-Club-Hub-HTML/network/members

[stars-shield]: https://img.shields.io/github/stars/vdhamer/Photo-Club-Hub-HTML?style=plastic
[stars-url]: https://github.com/vdhamer/Photo-Club-Hub-HTML/stargazers

[issues-shield]: https://img.shields.io/github/issues/vdhamer/Photo-Club-Hub-HTML?style=plastic
[issues-url]: https://github.com/vdhamer/Photo-Club-Hub-HTML/issues

[discussions-shield]: https://img.shields.io/github/discussions/vdhamer/Photo-Club-Hub-HTML?style=plastic?color=orange
[discussions-url]: https://github.com/vdhamer/Photo-Club-Hub-HTML/discussions

[license-shield]: https://img.shields.io/github/license/vdhamer/Photo-Club-Hub-HTML?style=plastic
[license-url]: https://github.com/vdhamer/Photo-Club-Hub-HTML/blob/main/.github/LICENSE.md
