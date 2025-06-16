# Vinylogue for Last.fm

Vinylogue is a SwiftUI-based Last.fm client for iOS that shows you and your friends' weekly music charts from previous years.

**🚧 This is a complete SwiftUI rewrite of the original Objective-C app**

* [Original App Store](https://itunes.apple.com/us/app/vinylogue-for-last.fm/id617471119?ls=1&mt=8) (legacy version)
* [Landing page](http://twocentstudios.com/apps/vinylogue/) with screenshots from the original app
* [Original blog post](http://twocentstudios.com/blog/2013/04/03/the-making-of-vinylogue/) about the legacy implementation

## Features

- **iOS 18.0+ SwiftUI** - Modern, native iOS interface
- **Automatic Data Migration** - Seamlessly migrate from legacy Objective-C version
- **User Onboarding** - Clean setup flow with Last.fm username validation
- **Friend Curation** - Import friends from Last.fm and curate your personal list
- **Weekly Charts** - Browse your and your friends' music history (coming in Sprint 4)
- **Album Details** - Rich album information and statistics (coming in Sprint 5)

## Getting Started

### Prerequisites
- Xcode 16.0+ (iOS 18.0+ SDK)
- XcodeGen (install with `brew install xcodegen`)
- Last.fm API key ([get one here](https://www.last.fm/api))

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone git://github.com/twocentstudios/vinylogue.git
   cd vinylogue
   ```

2. **Add your Last.fm API key**
   ```bash
   # Create the secrets file
   echo 'enum Secrets { static let lastFMAPIKey = "YOUR_API_KEY_HERE" }' > Vinylogue/Shared/Services/Secrets.swift
   ```

3. **Generate the Xcode project**
   ```bash
   xcodegen generate
   ```

4. **Open and build**
   ```bash
   open Vinylogue.xcodeproj
   ```

### Project Structure
- **XcodeGen-based** - Project file is generated from `project.yml`
- **Swift Package Manager** - Dependencies managed via SPM (Nuke for image loading)
- **SwiftUI + iOS 18.0+** - Modern iOS development stack

## Migration & Onboarding

### Automatic Data Migration

The app automatically migrates data from the legacy Objective-C version on first launch:

**What gets migrated:**
- Last.fm username from `NSUserDefaults`
- User settings (play count filters, etc.)
- Cached friends data from JSON files

**Migration Process:**
1. **Detection** - App checks for legacy data on startup
2. **Migration** - `LegacyMigrator` converts old format to new SwiftUI state
3. **Cleanup** - Legacy files and preferences are safely removed
4. **Logging** - Migration status logged via OSLog for debugging

**For Developers:**
- Migration is implemented in `LegacyMigrator.swift`
- Unit tested with temporary directories in `LegacyMigratorTests.swift`
- Migration runs once and is marked complete via UserDefaults flag

### User Onboarding

New users (or users with no legacy data) see a clean onboarding flow:

**Onboarding Steps:**
1. **Welcome Screen** - App introduction and branding
2. **Username Entry** - TextField for Last.fm username
3. **Validation** - Real-time validation against Last.fm API
4. **Setup Complete** - Automatic navigation to main app

**Implementation Details:**
- `OnboardingView.swift` - SwiftUI interface with form validation
- Last.fm API integration for username verification
- Proper error states for network issues and invalid usernames
- Accessibility support with VoiceOver labels and keyboard navigation

**Flow Logic:**
```swift
// RootView determines app state:
if !isMigrationComplete {
    MigrationLoadingView()  // Show during migration
} else if hasCurrentUser {
    UsersListView()         // User is set up, show main app
} else {
    OnboardingView()        // New user needs setup
}
```

## Friend Management

### Friend Curation Interface

The app provides a comprehensive friend management system for curating your personal list of Last.fm friends:

**Friend Curation Features:**
- **Import from Last.fm** - Automatically fetch your complete friends list from Last.fm API
- **Manual Friend Addition** - Add friends by username with real-time validation
- **Drag-to-Reorder** - Rearrange friends list using intuitive drag gestures
- **Persistent Storage** - Friend list automatically saved to device storage
- **Smart Filtering** - Only show friends not already in your curated list

**Usage:**
1. **Access Friend Curation** - Tap "Edit" button in the top-right of the users list
2. **Import Friends** - Use "Import from Last.fm" to fetch your complete friends list
3. **Add Friends Manually** - Use "Add Friend" to manually enter usernames
4. **Curate Your List** - Select/deselect friends and drag to reorder
5. **Save Changes** - Tap "Done" to persist your curated friends list

**Implementation Details:**
- `FriendsImporter.swift` - Service for fetching friends from Last.fm API
- `EditFriendsView.swift` - SwiftUI interface for friend curation
- `Environment+Keys.swift` - Environment injection for curated friends state
- Comprehensive unit tests in `FriendsImporterTests.swift`

**Friend Data Structure:**
```swift
struct User: Codable, Identifiable, Hashable {
    let username: String
    let realName: String?
    let imageURL: String?
    let url: String?
    let playCount: Int?
}
```

The curated friends list is automatically synchronized across the app using SwiftUI's Environment system, ensuring consistent state management throughout the user interface.

## Architecture

### SwiftUI + Modern iOS Development

This rewrite serves as a practical example of modern iOS development patterns:

**Core Technologies:**
- **SwiftUI** - Declarative UI framework with iOS 18.0+ features
- **Async/Await** - Modern concurrency for API calls and data migration
- **Environment Values** - SwiftUI's dependency injection system
- **XcodeGen** - Declarative project generation and maintenance

**Key Patterns:**
- **MVVM Architecture** - Clear separation between Views, ViewModels, and Models
- **Environment-based State Management** - Using SwiftUI's `@Environment` for app state
- **Service Layer** - Dedicated services for API calls, caching, and migration
- **Comprehensive Testing** - Unit tests with proper isolation and mocking

**API Integration:**
- RESTful Last.fm API client with proper error handling
- JSON parsing with `Codable` and custom date formatting
- Image loading and caching via [Nuke](https://github.com/kean/Nuke)

**Migration Strategy:**
- Safe, reversible data migration from legacy Core Data + UserDefaults
- Comprehensive logging and error recovery
- Isolated unit testing with temporary directories

### Learning from the Source

The original [blog post](http://twocentstudios.com/blog/2013/04/03/the-making-of-vinylogue/) covers the ReactiveCocoa-based legacy implementation. This SwiftUI rewrite demonstrates equivalent functionality using modern iOS development practices.

**Helpful for learning:**
- SwiftUI app architecture and state management patterns
- Last.fm API integration with modern Swift concurrency
- Data migration strategies for iOS app rewrites
- XcodeGen project management workflows

## Testing

The project includes comprehensive unit tests covering core functionality:

```bash
# Run all tests
xcodebuild test -project Vinylogue.xcodeproj -scheme Vinylogue -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test suite
xcodebuild test -project Vinylogue.xcodeproj -scheme Vinylogue -only-testing:VinylogueTests/LegacyMigratorTests
```

**Test Coverage:**
- **LegacyMigratorTests** - Migration scenarios with temporary directories
- **LastFMClientTests** - API integration and JSON parsing
- **FriendsImporterTests** - Friend import and curation functionality
- **Model Tests** - Data transformation and validation

**Testing Patterns:**
- Isolated test environments with temporary UserDefaults and directories
- Comprehensive migration scenario coverage (no data, partial data, full migration)
- API client testing with mock responses and error conditions

## Development Workflow

1. **Make changes** to source files
2. **Regenerate project** if needed: `xcodegen generate`
3. **Run tests** to ensure functionality: `xcodebuild test ...`
4. **Build and verify** the app works as expected

## License

License for source is Modified BSD. If there's enough interest, I can modularize particular parts of the source into their own MIT Licensed components.

All rights are reserved for image assets.

## Contributing

This SwiftUI rewrite is an ongoing learning project exploring modern iOS development patterns. Contributions, improvements, and feedback are welcome!

**How to contribute:**
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Ensure all tests pass (`xcodebuild test ...`)
5. Submit a pull request

**Guidelines:**
- Follow existing SwiftUI and Swift code patterns
- Add unit tests for new functionality
- Update documentation as needed
- Use XcodeGen for project changes

## About

**Original App**: Vinylogue was created by [Christopher Trott](http://twitter.com/twocentstudios) at [twocentstudios](http://twocentstudios.com).

**SwiftUI Rewrite**: This modern implementation demonstrates current iOS development best practices while maintaining the core functionality that made the original app popular.

---

*This rewrite serves as both a functional Last.fm client and a learning resource for modern iOS development. The original ReactiveCocoa-based implementation remains available in git history for comparison.*
