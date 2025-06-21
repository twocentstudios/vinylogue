# Vinylogue for Last.fm

Vinylogue is a SwiftUI-based Last.fm client for iOS that shows you and your friends' weekly music charts from previous years.

**🎉 This is a complete SwiftUI rewrite of the original Objective-C app**

* [Original App Store](https://itunes.apple.com/us/app/vinylogue-for-last.fm/id617471119?ls=1&mt=8) (legacy version)
* [Landing page](http://twocentstudios.com/apps/vinylogue/) with screenshots from the original app
* [Original blog post](http://twocentstudios.com/blog/2013/04/03/the-making-of-vinylogue/) about the legacy implementation

![Screenshots coming soon](Planning/screenshots/)

## Features

- **iOS 18.0+ SwiftUI** - Modern, native iOS interface matching the original design
- **Automatic Data Migration** - Seamlessly migrate from legacy Objective-C version
- **User Onboarding** - Clean setup flow with Last.fm username validation
- **Friend Management** - Import friends from Last.fm and curate your personal list
- **Weekly Charts** - Browse your and your friends' music history by year
- **Album Details** - Rich album information with dynamic color theming
- **Legacy Design Preservation** - Pixel-perfect recreation of the original app's aesthetic

## Getting Started

### Prerequisites
- Xcode 16.0+ (iOS 18.0+ SDK)
- XcodeGen (install with `brew install xcodegen`)
- SwiftFormat (install with `brew install swiftformat`)
- Last.fm API key ([get one here](https://www.last.fm/api))

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

4. **Format and build**
   ```bash
   swiftformat .
   open Vinylogue.xcodeproj
   ```

## Architecture

This rewrite demonstrates modern iOS development patterns and serves as a practical learning resource.

### Core Technologies
- **SwiftUI** with @Observable state management
- **Point-Free Dependencies** for dependency injection
- **Point-Free Sharing** for global state management
- **Swift Concurrency** (async/await) throughout
- **Nuke** for advanced image loading and caching

### Key Patterns
- **Store-View Architecture** - @Observable stores paired with SwiftUI views
- **Type-Safe Navigation** - Enum-based navigation with shared state
- **Legacy Migration** - Safe NSCoding → Codable conversion
- **Dynamic Color Theming** - UI adapts to album artwork colors
- **NO DARK MODE** - Preserves original light-mode-only design

### Project Structure
- **Core/** - Foundation layer (models, services, infrastructure, reusable views)
- **Features/** - Business logic layer (Root, UserManagement, Main features)
- **XcodeGen-based** - Project file generated from `project.yml`

## Development Workflow

```bash
# After adding/removing/renaming files
xcodegen

# Format code before committing
swiftformat .

# Build with quiet output
xcodebuild -quiet

# Run tests
xcodebuild test -quiet
```

## Testing

Comprehensive unit test coverage including:

- **Legacy Migration** - Data migration scenarios with temporary environments
- **Last.fm API Integration** - API client with mock responses and error conditions
- **Friends Management** - Import and curation functionality
- **Color Extraction** - Image processing with edge cases

Run tests with:
```bash
xcodebuild test -project Vinylogue.xcodeproj -scheme Vinylogue -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Migration & Legacy Support

The app automatically migrates data from the legacy Objective-C version:

**What gets migrated:**
- Last.fm username and settings
- Cached friends data
- User preferences

**Migration Process:**
1. Detection of legacy data on startup
2. Safe conversion via `LegacyMigrator` 
3. Cleanup of old files and preferences
4. Comprehensive logging for debugging

New users see a clean onboarding flow with Last.fm username validation.

## License

License for source is Modified BSD. If there's enough interest, I can modularize particular parts of the source into their own MIT Licensed components.

All rights are reserved for image assets.

## Contributing

This SwiftUI rewrite is nearing completion and will be released as open source. Contributions and feedback are welcome!

**Development Guidelines:**
- Follow existing SwiftUI and @Observable patterns
- Add unit tests for new functionality
- Use XcodeGen for project structure changes
- Format code with SwiftFormat before committing
- Reference Planning/PRD.md and Planning/screenshots/ for design requirements

## About

**Original App**: Vinylogue was created by [Christopher Trott](http://twitter.com/twocentstudios) at [twocentstudios](http://twocentstudios.com).

**SwiftUI Rewrite**: This modern implementation preserves the beloved original design while demonstrating current iOS development best practices.

---

*This rewrite serves as both a functional Last.fm client and a comprehensive example of modern iOS architecture patterns. The original ReactiveCocoa-based implementation remains available in git history for comparison.*