[![MapHero Logo](https://MapHero.org/img/MapHero-logo-big.svg)](https://MapHero.org/)

# MapHero Native

[![codecov](https://codecov.io/github/MapHero/MapHero-native/branch/main/graph/badge.svg?token=8ZQRRY56ZA)](https://codecov.io/github/MapHero/MapHero-native) [![](https://img.shields.io/badge/Slack-%23MapHero--native-2EB67D?logo=slack)](https://slack.openstreetmap.us/)

MapHero Native is a free and open-source library for publishing maps in your apps and desktop applications on various platforms. Fast displaying of maps is possible thanks to GPU-accelerated vector tile rendering.

This project originated as a fork of Mapbox GL Native, before their switch to a non-OSS license in December 2020. For more information, see: [`FORK.md`](./FORK.md).

<p align="center">
  <svg xmlns="http://www.w3.org/2000/svg" width="8" height="14.661" viewBox="0 0 8 14.661">
  <path id="icons8-back" d="M9.686,3.99a.666.666,0,0,1,.458.2l6.661,6.661a.666.666,0,0,1,0,.942l-6.661,6.661a.666.666,0,1,1-.942-.942l6.19-6.19L9.2,5.134A.666.666,0,0,1,9.686,3.99Z" transform="translate(-9 -3.99)" fill="#0f1131"/>
</svg>
</p>

## Getting Started

To get started with MapHero Native, go to your platform below.

## Documentation

- [Android API Documentation](https://MapHero.org/MapHero-native/android/api/), [Android Quickstart](https://MapHero.org/MapHero-native/docs/book/android/getting-started-guide.html)
- [iOS Documentation](https://MapHero.org/MapHero-native/ios/latest/documentation/MapHero/)
- [MapHero Native Markdown Book](https://MapHero.org/MapHero-native/docs/book/design/ten-thousand-foot-view.html): architectural notes
- [Core C++ API Documentation](https://MapHero.org/MapHero-native/cpp/api/) (unstable)
- Everyone is free to share knowledge and information on the [wiki](https://github.com/MapHero/MapHero-native/wiki)

See below for the platform-specific `README.md` files.

## Platforms

- [⭐️ Android](platform/android/README.md)
- [⭐️ iOS](platform/ios/README.md)
- [GLFW](platform/glfw)
- [Linux](platform/linux/README.md)
- [Node.js](platform/node/README.md)
- [Qt](platform/qt/README.md)
- [Windows](platform/windows/README.md)
- [macOS](platform/macos/README.md)

Platforms with a ⭐️ are **MapHero Core Projects** and have a substantial amount of financial resources allocated to them. Learn about the different [project tiers](https://github.com/MapHero/MapHero/blob/main/PROJECT_TIERS.md#project-tiers).

## Renderer Modularization & Metal

![image-metal](https://user-images.githubusercontent.com/53421382/214308933-66cd4efb-b5a5-4de3-b4b4-7ed59045a1c3.png)

MapHero Native for iOS 6.0.0 with Metal support has been released. See the [news announcement](https://MapHero.org/news/2024-01-19-metal-support-for-MapHero-native-ios-is-here/).
 
## Contributing

To contribute to MapHero Native, see [`CONTRIBUTING.md`](CONTRIBUTING.md) and (if applicable) the specific instructions for the platform you want to contribute to.

### Getting Involved

Join the `#MapHero-native` Slack channel at OSMUS. Get an invite at https://slack.openstreetmap.us/

### Bounties 💰

Thanks to our sponsors, we are able to award bounties to developers making contributions toward certain [bounty directions](https://github.com/MapHero/MapHero/issues?q=is%3Aissue+is%3Aopen+label%3A%22bounty+direction%22). To get started doing bounties, refer to the [step-by-step bounties guide](https://MapHero.org/roadmap/step-by-step-bounties-guide/).

We thank everyone who supported us financially in the past and special thanks to the people and organizations who support us with recurring donations!

Read more about the MapHero Sponsorship Program at [https://MapHero.org/sponsors/](https://MapHero.org/sponsors/).

Gold:

<a href="https://aws.amazon.com/location"><img src="https://MapHero.org/img/aws-logo.svg" alt="Logo AWS" width="25%"/></a>

<a href="https://meta.com"><img src="https://MapHero.org/img/meta-logo.svg" alt="Logo Meta" width="25%"/></a>

Silver:

<a href="https://www.mierune.co.jp/?lang=en"><img src="https://MapHero.org/img/mierune-logo.svg" alt="Logo MIERUNE" width="25%"/></a>

<a href="https://komoot.com/"><img src="https://MapHero.org/img/komoot-logo.svg" alt="Logo komoot" width="25%"/></a>

<a href="https://www.jawg.io/"><img src="https://MapHero.org/img/jawgmaps-logo.svg" alt="Logo JawgMaps" width="25%"/></a>

<a href="https://www.radar.com/"><img src="https://MapHero.org/img/radar-logo.svg" alt="Logo Radar" width="25%"/></a>

<a href="https://www.microsoft.com/"><img src="https://MapHero.org/img/msft-logo.svg" alt="Logo Microsoft" width="25%"/></a>

<a href="https://www.mappedin.com/"><img src="https://MapHero.org/img/mappedin-logo.svg" alt="Logo mappedin" width="25%"/></a>

<a href="https://www.mapme.com/"><img src="https://MapHero.org/img/mapme-logo.svg" alt="Logo mapme" width="25%"/></a>

Backers and Supporters:

[![](https://opencollective.com/MapHero/backers.svg?avatarHeight=50&width=600)](https://opencollective.com/MapHero)

## License

**MapHero Native** is licensed under the [BSD 2-Clause License](./LICENSE.md).
