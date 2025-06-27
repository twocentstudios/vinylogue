# Vinylogue for Last.fm

Vinylogue is a Last.fm client for iOS that shows you and your friends' weekly music charts from previous years.

* [App Store](https://itunes.apple.com/us/app/vinylogue-for-last.fm/id617471119?ls=1&mt=8)
* [Landing page](https://twocentstudios.com/apps/vinylogue/)
* [v1 post](https://twocentstudios.com/2013/04/03/the-making-of-vinylogue/) about the legacy implementation
* [v2 post](https://twocentstudios.com/2025/06/22/vinylogue-swift-rewrite/) about the Swift rewrite with Claude Code

Home|Charts|Album
-|-|-
![Home](https://github.com/user-attachments/assets/27129334-fd7d-435d-a388-51ba4f215ddb)|![Charts](https://github.com/user-attachments/assets/3a0710da-d42a-49ed-b14d-a88a63ad957c)|![Album](https://github.com/user-attachments/assets/0505f298-96e6-4267-b382-ab9a0808a05f)

## Features

- **iOS 18.0+ SwiftUI**
- **Weekly Charts** - Browse you and your friends' listening for this week in history by year
- **Album Details** - View album listening history and info from last.fm
- **Friend Management** - Import friends from Last.fm

## Getting Started

### Prerequisites
- Xcode 16.0+ (iOS 18.0+)
- XcodeGen (install with `brew install xcodegen`)
- SwiftFormat (install with `brew install swiftformat`)
- Last.fm developer API key

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone git://github.com/twocentstudios/vinylogue.git
   cd vinylogue
   ```

2. **Add your Last.fm API key**
   ```bash
   # Copy the example secrets file
   cp Secrets.example.swift Vinylogue/Core/Infrastructure/Secrets.swift
   # Then edit the file to add your API key
   ```

3. **Generate the Xcode project**
   ```bash
   xcodegen
   ```

4. **build**
   ```bash
   open Vinylogue.xcodeproj
   ```

## Architecture

### Core Technologies

- **SwiftUI** with @Observable state management
- **Point-Free Dependencies** for dependency injection
- **Point-Free Sharing** for global state management
- **Swift Concurrency** (async/await) throughout
- **Nuke** for remote images

## Migration & Legacy Support

Version 2.0 automatically migrates data from the legacy Objective-C versions v1.0 - v1.3.1:

**What gets migrated:**

- Last.fm username
- Selected friends
- Play count filter

## License

License for source is Modified BSD.

All rights are reserved for image assets.

## Contributing

Contributions and feedback are welcome. Open an Issue on the repo with your ideas first.

## About

vinylogue was created by [Christopher Trott](http://twitter.com/twocentstudios) at [twocentstudios](http://twocentstudios.com).

## History

I created vinylogue in 2013 as an Objective-C, UIKit, and ReactiveCocoa app for iOS 6. It was released on the App Store and open sourced on GitHub. Over the years, I've updated the app to run well on newer versions of iOS without making any functional changes.

In 2025, with the help of Claude Code, I rewrote the app from the ground up in modern Swift and SwiftUI with a few quality of life improvements, but overall the same design and navigation. The app is simple, but just complex enough be a useful playground for trying out new app architectures and development tools. Plus, I still use it to check out my listening history.
