# Vinylogue 2.0 – Enhanced Product Requirements Document (v0.3)

**Date:** 2025‑06‑16  
**Target platform:** iOS 18.0+ (SwiftUI‑only implementation)  
**Original app:** Vinylogue (2011-2024, Objective‑C + UIKit)  
**Implementation strategy:** LLM-optimized with step-by-step validation

---

## 1. Purpose

Rewrite the established Last.fm companion app in **Swift + SwiftUI** while preserving the original user experience and functionality. The new architecture removes Objective‑C, UIKit, Combine and Core Data dependencies, focusing on a lightweight, async/await‑driven codebase that is maintainable and follows modern iOS development patterns.

---

## 2. Background & Legacy Analysis

### 2.1 Current Implementation
Legacy implementation (40+ Objective‑C files) successfully operating since 2011:
- **API Layer**: `TCSLastFMAPIClient` using AFNetworking with ReactiveCocoa
- **Data Models**: Core Data entities for User, Album, Artist, WeeklyChart relationships  
- **Storage**: NSUserDefaults with NSKeyedArchiver for user/friends persistence
- **UI Layer**: Custom UIKit views with manual color extraction and animations
- **Design System**: AvenirNext fonts, specific color palette, custom navigation patterns

### 2.2 Proven Patterns to Preserve
- Last.fm API integration with specific endpoints and robust error handling
- Image-based dominant color extraction for dynamic UI theming
- User and friends list management with reliable persistent storage
- Weekly album chart data caching with graceful offline support
- Custom year navigation with boundary handling

Screenshots of the target design are available in */Planning/screenshots/*.

---

## 3. Last.fm API Specification

### 3.1 Base Configuration
```swift
// Base URL and authentication
static let baseURL = "https://ws.audioscrobbler.com/2.0/"
static let apiKey = "7038b97535c628c428edb5e23427fee1" // From legacy implementation
static let format = "json"
```

### 3.2 Core Endpoints

#### 3.2.1 User Weekly Chart List
```swift
// GET https://ws.audioscrobbler.com/2.0/
// Parameters:
{
  "method": "user.getweeklychartlist",
  "user": "{username}",
  "api_key": "{api_key}",
  "format": "json"
}

// Response Schema:
{
  "weeklychartlist": {
    "chart": [
      {
        "from": "1108296000",  // Unix timestamp
        "to": "1108900800"     // Unix timestamp  
      }
    ]
  }
}
```

#### 3.2.2 User Weekly Album Chart
```swift
// GET https://ws.audioscrobbler.com/2.0/
// Parameters:
{
  "method": "user.getweeklyalbumchart",
  "user": "{username}",
  "from": "{unix_timestamp}",
  "to": "{unix_timestamp}",
  "api_key": "{api_key}",
  "format": "json"
}

// Response Schema:
{
  "weeklyalbumchart": {
    "album": [
      {
        "artist": {"name": "Artist Name"},
        "name": "Album Name",
        "playcount": "28",
        "rank": "1",
        "url": "https://...",
        "image": [
          {"#text": "https://...", "size": "small"},
          {"#text": "https://...", "size": "medium"},
          {"#text": "https://...", "size": "large"}
        ]
      }
    ]
  }
}
```

#### 3.2.3 Album Details
```swift
// GET https://ws.audioscrobbler.com/2.0/
// Parameters (option 1 - by MBID):
{
  "method": "album.getinfo",
  "mbid": "{musicbrainz_id}",
  "api_key": "{api_key}",
  "format": "json",
  "username": "{username}" // Optional for user-specific data
}

// Parameters (option 2 - by artist/album):
{
  "method": "album.getinfo",
  "artist": "{artist_name}",
  "album": "{album_name}",
  "api_key": "{api_key}",
  "format": "json",
  "username": "{username}" // Optional
}

// Response Schema:
{
  "album": {
    "name": "Album Name",
    "artist": "Artist Name",
    "url": "https://...",
    "image": [...],
    "playcount": "123456",
    "userplaycount": "28", // If username provided
    "wiki": {
      "summary": "Album description...",
      "content": "Full description..."
    }
  }
}
```

#### 3.2.4 User Friends List
```swift
// GET https://ws.audioscrobbler.com/2.0/
// Parameters:
{
  "method": "user.getfriends",
  "user": "{username}",
  "limit": "500", // Max 500 friends
  "api_key": "{api_key}",
  "format": "json"
}

// Response Schema:
{
  "friends": {
    "user": [
      {
        "name": "username",
        "realname": "Real Name",
        "url": "https://...",
        "image": [...]
      }
    ]
  }
}
```

#### 3.2.5 User Info
```swift
// GET https://ws.audioscrobbler.com/2.0/
// Parameters:
{
  "method": "user.getinfo",
  "user": "{username}",
  "api_key": "{api_key}",
  "format": "json"
}

// Response Schema:
{
  "user": {
    "name": "username",
    "realname": "Real Name",
    "url": "https://...",
    "image": [...],
    "playcount": "123456"
  }
}
```

### 3.3 Error Handling
Last.fm API returns errors in this format:
```json
{
  "error": 6,
  "message": "User not found"
}
```

Common error codes:
- `2`: Invalid service
- `3`: Invalid method  
- `4`: Authentication failed
- `6`: Invalid parameters
- `8`: Operation failed
- `9`: Invalid session key
- `10`: Invalid API key
- `11`: Service offline
- `16`: Temporarily unavailable

---

## 4. Functional Requirements

### 4.1 Core Features with Acceptance Criteria

|  ID  |  Feature                    |  Acceptance Criteria |  Test Scenario |
| ---- | --------------------------- | -------------------- | -------------- |
|  F1  | **Seamless data migration** | On first run after upgrade from v1.3.1, migrate legacy `NSUserDefaults` keys (`kTCSUserDefaultsLastFMUserName`, `kTCSUserDefaultsLastFMFriendsList`, `kTCSUserDefaultsPlayCountFilter`) into new `@Shared` storage with **zero data loss**. | Install v1.3.1 → Add user "testuser" + 3 friends → Upgrade to v2.0 → Verify all data preserved |
|  F2  | **Onboarding flow**         | Username entry view appears if no current user found. Validates against Last.fm API before saving to `@Shared` storage. | Fresh install → Launch app → Enter valid username "ybsc" → Proceed to main interface |
|  F3  | **Friend curation**         | Import full Last.fm friends list (max 500), allow manual editing + drag-to-reorder. Persist curated list in `@Shared` under key `curatedFriends`. | User with 10 friends → Import all → Remove 3 → Reorder remaining → Verify persistence |
|  F4  | **User selection interface** | Root NavigationStack shows current user (bold "me" label) + curated friends below. Tapping navigates to WeeklyAlbumsView for that user. | Display user "ybsc" + friends → Tap friend "BobbyStompy" → Navigate to their weekly charts |
|  F5  | **Weekly albums display**   | Display albums for same calendar week N years ago, showing artwork (150x150), title, artist, play count. Sort by play count descending. Cache JSON responses. | Week 25 of 2020 for user "ybsc" → Show 4 albums → Verify sorting by play count |
|  F6  | **Year navigation**         | Safe area buttons: "← Previous Year" (bottom), "Next Year →" (top). Hide if no data available for that year. | 2024 data → Show previous button → 2015 (oldest) → Hide previous button |
|  F7  | **Album detail view**       | Full-screen with dominant color background extracted from artwork. Shows large artwork, title, artist, play counts, description. Animate fade/scale entrance (0.3s ease-out). | Tap album → Extract dominant color → Animate entrance → Display all metadata |
|  F8  | **Settings sheet**          | Modal presentation with SF Symbols "gearshape.fill" trigger. Options: change username, refresh friends, adjust play count filter (off/1/2/4/8/16/32), support links. | Tap settings → Modal appears → Change filter to 10 → Verify persistence |
|  F9  | **API response caching**    | Write raw JSON responses to `FileManager.temporaryDirectory/VinylogueCache/{username}/{from}-{to}.json`. Return cached data if network unavailable. | Network request → Cache response → Disable network → Verify cached data loads |
|  F10 | **Image caching**           | Use Nuke framework with custom disk cache at `FileManager.temporaryDirectory/VinylogueImages/{url_hash}`. Implement LRU eviction. | Load 20 album covers → Verify disk cache → Restart app → Verify images load from cache |
|  F11 | **Dynamic Type support**    | Scale text using `Font.custom("AvenirNext-Medium", size: UIFont.preferredFont(forTextStyle: .body).pointSize)` pattern. Support sizes from XS to XXXL. | Set Dynamic Type to XXXL → Verify all text scales appropriately |

### 4.2 Non-Functional Requirements

| Category | Requirement | Test Method |
|----------|------------|-------------|
| **Performance** | App launch to UsersListView ≤ 300ms on iPhone 15 | Xcode Instruments Time Profiler |
| **Memory** | Peak memory usage ≤ 150MB during normal browsing | Xcode Memory Graph Debugger |
| **Network** | API requests timeout after 30s with 2 retries | Unit tests with URLProtocol mocking |
| **Offline** | Graceful degradation when network unavailable | Airplane mode testing |
| **Accessibility** | VoiceOver labels for all interactive elements | Accessibility Inspector validation |
| **Storage** | Cache size management with automatic cleanup | Monitor disk usage over time |

---

## 5. Architecture & Implementation

### 5.1 Project Structure
```
Sources/
├── VinylogueApp/
│   ├── VinylogueApp.swift              # @main App entry point
│   ├── AppConfiguration.swift          # Environment setup
│   └── Secrets.swift                   # API keys (gitignored)
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   └── UsernameValidator.swift
│   ├── Users/
│   │   ├── UsersListView.swift
│   │   └── UserRowView.swift
│   ├── WeeklyCharts/
│   │   ├── WeeklyAlbumsView.swift
│   │   ├── AlbumRowView.swift
│   │   └── YearNavigationView.swift
│   ├── AlbumDetail/
│   │   ├── AlbumDetailView.swift
│   │   ├── ColorExtractionView.swift
│   │   └── AlbumInfoView.swift
│   └── Settings/
│       ├── SettingsSheet.swift
│       └── PlayCountFilterView.swift
├── Shared/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Album.swift
│   │   ├── WeeklyChart.swift
│   │   └── LastFMResponse.swift
│   ├── Services/
│   │   ├── LastFMClient.swift
│   │   ├── CacheManager.swift
│   │   └── MigrationManager.swift
│   ├── Extensions/
│   │   ├── Font+Vinylogue.swift
│   │   ├── Color+DominantColor.swift
│   │   └── Environment+Keys.swift
│   └── Utilities/
│       ├── NetworkMonitor.swift
│       └── Logger.swift
└── Resources/
    ├── Fonts/
    └── Colors.xcassets
```

### 5.2 Data Models
```swift
// User.swift
struct User: Codable, Identifiable, Hashable {
    let id = UUID()
    let username: String
    let realName: String?
    let imageURL: String?
    let url: String?
    let playCount: Int?
    
    // Legacy migration keys
    static let legacyUserDefaultsKey = "kTCSUserDefaultsLastFMUserName"
}

// Album.swift  
struct Album: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let artist: String
    let imageURL: String?
    let playCount: Int
    let rank: Int?
    let url: String?
    let mbid: String?
    
    // Detail view properties (loaded separately)
    var description: String?
    var totalPlayCount: Int?
    var userPlayCount: Int?
    var isDetailLoaded: Bool = false
}

// WeeklyChart.swift
struct WeeklyChart: Codable, Identifiable, Hashable {
    let id = UUID()
    let from: Date
    let to: Date
    let albums: [Album]
    
    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: from)
    }
    
    var year: Int {
        Calendar.current.component(.year, from: from)
    }
}
```

### 5.3 Environment Keys
```swift
// Environment+Keys.swift
private struct LastFMClientKey: EnvironmentKey {
    static let defaultValue = LastFMClient()
}

private struct ImagePipelineKey: EnvironmentKey {
    static let defaultValue = ImagePipeline.shared
}

private struct PlayCountFilterKey: EnvironmentKey {
    static let defaultValue: Int = 1
}

extension EnvironmentValues {
    var lastFMClient: LastFMClient {
        get { self[LastFMClientKey.self] }
        set { self[LastFMClientKey.self] = newValue }
    }
    
    var imagePipeline: ImagePipeline {
        get { self[ImagePipelineKey.self] }
        set { self[ImagePipelineKey.self] = newValue }
    }
    
    var playCountFilter: Int {
        get { self[PlayCountFilterKey.self] }
        set { self[PlayCountFilterKey.self] = newValue }
    }
}
```

### 5.4 App Entry Point
```swift
// VinylogueApp.swift
@main
struct VinylogueApp: App {
    @State private var lastFMClient = LastFMClient()
    @State private var imagePipeline = ImagePipeline(
        configuration: .withTemporaryDiskCache()
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.lastFMClient, lastFMClient)
                .environment(\.imagePipeline, imagePipeline)
                .task {
                    // Perform migration on app launch
                    await MigrationManager.shared.migrateIfNeeded()
                }
        }
    }
}
```

---

## 6. Design System

### 6.1 Typography
```swift
// Font+Vinylogue.swift
extension Font {
    // Legacy font mappings from TCSVinylogueDesign.h
    static func vinylogueTitle() -> Font {
        .custom("AvenirNext-DemiBold", 
                size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }
    
    static func vinylogueBody() -> Font {
        .custom("AvenirNext-Medium",
                size: UIFont.preferredFont(forTextStyle: .body).pointSize)
    }
    
    static func vinylogueCaption() -> Font {
        .custom("AvenirNext-Regular",
                size: UIFont.preferredFont(forTextStyle: .caption1).pointSize)
    }
    
    static func vinylogueUltraLight(_ size: CGFloat) -> Font {
        .custom("AvenirNext-UltraLight", size: size)
    }
}
```

### 6.2 Color Palette
```swift
// Color+Vinylogue.swift
extension Color {
    // Legacy color mappings from TCSVinylogueDesign.h
    static let vinylogueBackground = Color(red: 240/255, green: 240/255, blue: 240/255)
    static let vinylogue darkBlue = Color(red: 15/255, green: 24/255, blue: 46/255)
    static let vinylogue boldBlue = Color(red: 67/255, green: 85/255, blue: 129/255)
    static let vinylogueButtonTint = Color(red: 220/255, green: 220/255, blue: 220/255)
}
```

### 6.3 Dominant Color Extraction
```swift
// Color+DominantColor.swift - Replaces UIImage+TCSImageRepresentativeColors
extension UIImage {
    func dominantColors() async -> (primary: Color, secondary: Color, text: Color) {
        // Algorithm: Sample image pixels, cluster colors, return most prominent
        // Implementation should match legacy color extraction logic
        return await withCheckedContinuation { continuation in
            // Async color extraction implementation
        }
    }
}
```

---

## 7. Data Migration Strategy

### 7.1 Legacy Data Detection
```swift
// MigrationManager.swift
class MigrationManager {
    static let shared = MigrationManager()
    
    func migrateIfNeeded() async {
        guard needsMigration() else { return }
        
        do {
            let legacyData = try extractLegacyData()
            try await migrateTo newStorage(legacyData)
            markMigrationComplete()
        } catch {
            Logger.error("Migration failed: \(error)")
            // Graceful fallback to fresh install
        }
    }
    
    private func needsMigration() -> Bool {
        // Check for legacy NSUserDefaults keys
        UserDefaults.standard.object(forKey: "kTCSUserDefaultsLastFMUserName") != nil ||
        UserDefaults.standard.object(forKey: "kTCSUserDefaultsLastFMFriendsList") != nil
    }
    
    private func extractLegacyData() throws -> LegacyData {
        // Parse NSKeyedArchiver data from UserDefaults
        // Handle NSCoding protocol bridging
    }
}
```

### 7.2 Storage Validation
```swift
// Post-migration validation
func validateMigration() -> Bool {
    // Verify all expected data is present in new storage
    // Compare counts and key data points
    // Return false if any critical data is missing
}
```

---

## 8. Error Handling & Loading States

### 8.1 Network Error States
```swift
enum LastFMError: Error, LocalizedError {
    case invalidAPIKey
    case userNotFound
    case networkUnavailable
    case invalidResponse
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API configuration"
        case .userNotFound:
            return "User not found. Please check the username."
        case .networkUnavailable:
            return "Network unavailable. Showing cached data."
        case .invalidResponse:
            return "Unable to load data. Please try again."
        case .serviceUnavailable:
            return "Last.fm service is temporarily unavailable"
        }
    }
}
```

### 8.2 Loading State Management
```swift
// Loading states for each view
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
}

// Usage in views
@State private var albumsState: LoadingState<[Album]> = .idle
```

---

## 9. Testing Strategy

### 9.1 Unit Tests
- [✅] LastFMClient API endpoint coverage
- [✅] Data model serialization/deserialization  
- [✅] Migration logic with various legacy data scenarios
- [✅] Cache management and eviction policies
- [✅] Error handling for all network failure modes
- [✅] FriendsImporter service with comprehensive test coverage
- [✅] WeeklyAlbumLoader with loading state management

### 9.2 Integration Tests  
- [ ] End-to-end user flows (onboarding → browsing → details)
- [ ] Offline behavior testing
- [ ] Performance testing with large friends lists
- [ ] Memory pressure testing with image loading

### 9.3 UI Tests
- [ ] VoiceOver navigation and announcement
- [ ] Dynamic Type scaling at all sizes
- [ ] Dark mode compatibility (future)
- [ ] iPad layout adaptation (future)

---

## 10. Implementation Milestones

### Sprint 0: Foundation (Files 1-8)
**Dependencies**: None  
**Validation**: Project builds successfully
- [x] Project structure and build configuration
- [x] Environment keys and dependency injection setup
- [x] Core data models (User, Album, WeeklyChart)
- [x] LastFMClient stub with basic networking
- [x] Font and color extensions
- [x] Basic app shell with navigation

### Sprint 1: API Integration (Files 9-15)
**Dependencies**: Sprint 0  
**Validation**: Network requests return expected data
- [✅] Complete LastFMClient implementation with all endpoints
- [✅] JSON response parsing and error handling
- [✅] Network monitoring and retry logic
- [✅] Cache manager with file system operations
- [✅] API integration tests

### Sprint 2: Data Migration (Files 16-20)
**Dependencies**: Sprint 1  
**Validation**: Legacy data successfully migrated
- [✅] MigrationManager with NSUserDefaults parsing
- [✅] Legacy data model bridging (NSCoding compatibility)
- [✅] Migration validation and rollback logic
- [✅] OnboardingView for new users
- [✅] Migration integration tests

### Sprint 3: Users Interface (Files 21-25)
**Dependencies**: Sprint 2  
**Validation**: User list displays and navigation works
- [✅] UsersListView with current user + friends
- [✅] User selection and navigation flow
- [✅] Friend curation (add/remove/reorder)
- [✅] Friends list persistence
- [✅] UI tests for user interactions

### Sprint 4: Weekly Charts (Files 26-35)
**Dependencies**: Sprint 3  
**Validation**: Album charts load and display correctly
- [✅] WeeklyAlbumsView with album grid
- [✅] Year navigation with boundary handling
- [✅] Album artwork loading with Nuke
- [✅] Play count filtering
- [✅] Loading and error states
- [✅] Performance testing with large datasets

### Sprint 5: Album Details (Files 36-42)
**Dependencies**: Sprint 4  
**Validation**: Detail view animates and displays metadata
- [✅] AlbumDetailView with full-screen layout
- [✅] Dominant color extraction from artwork
- [✅] Animated transitions and entrance effects
- [✅] Album metadata display (description, play counts)
- [✅] Accessibility labels and VoiceOver support

### Sprint 6: Settings & Polish (Files 43-48)
**Dependencies**: Sprint 5  
**Validation**: All settings persist and UI is polished
- [✅] SettingsSheet with modal presentation
- [✅] Username change functionality
- [✅] Play count filter with validation
- [✅] Support links and app information
- [✅] Final UI polish and accessibility testing

### Sprint 7: Testing & Release (Files 49-55)
**Dependencies**: Sprint 6  
**Validation**: All tests pass, ready for TestFlight
- [✅] Comprehensive test suite completion
- [✅] Performance optimization and memory profiling
- [✅] Final bug fixes and edge case handling
- [✅] TestFlight beta preparation
- [✅] App Store submission assets

### Post-Release Bug Fixes & Performance Improvements
**Date**: 2025-06-16  
**Status**: In Progress
- [✅] **Fixed play count filtering**: WeeklyAlbumsView now properly filters albums by the user's selected playCountFilter value
  - Modified WeeklyAlbumLoader to accept dynamic play count filter updates
  - Added `updatePlayCountFilter()` method to reload data when filter changes
  - Updated `isDataLoaded()` to include playCountFilter in comparison
  - WeeklyAlbumsView now responds to playCountFilter environment changes
- [✅] **Added comprehensive caching with CacheManager**: 
  - WeeklyAlbumLoader now caches weekly chart lists and album chart responses
  - LastFMClient.fetchAlbumInfo() now caches album detail responses  
  - Cache keys include user context and time periods for proper cache invalidation
  - Significant performance improvement for repeated API calls
- [✅] **Fixed legacy data migration bug**: 
  - `migrateFriendsToNewCache()` now saves friends to UserDefaults instead of temporary cache
  - Ensures migrated friends are properly available to the UsersListView
- [✅] **Fixed settings persistence bugs**:
  - Corrected key mismatch between settings save ("playCountFilter") and app read ("currentPlayCountFilter")
  - App now listens for UserDefaults changes and updates environment values automatically
  - Settings changes now persist correctly and reflect immediately in the UI
- [✅] **Improved settings UI**: Made play count filter cell fully tappable instead of just text labels
- [✅] **Fixed async test issues**: Removed problematic async operations from test tearDown methods
- [✅] **Fixed ChartCache load method**: Now properly returns nil when no cache data exists
- [✅] **Test suite updates**: All 71 tests now pass with the updated WeeklyAlbumLoader interface

**Remaining TODOs**:
- [✅] Fix WeeklyAlbumLoaderTests to work with updated initializer (removing playCountFilter parameter)
- [✅] Verify all 71+ tests pass with the new caching and filtering implementation
- [ ] Performance testing to validate caching improvements
- [ ] Consider adding cache size management and cleanup policies

---

## 11. Code Quality Standards

### 11.1 Coding Conventions
```swift
// Naming conventions
- Types: PascalCase (AlbumDetailView)
- Properties/methods: camelCase (playCountFilter)
- Constants: camelCase with context (maxFriendsCount)
- Environment keys: PascalCase with "Key" suffix (LastFMClientKey)

// File organization
- One primary type per file
- Extensions in separate files when substantial
- Group related functionality in folders
- Alphabetical ordering within groups
```

### 11.2 SwiftUI Patterns
```swift
// View composition
- Prefer ViewBuilder composition over large body properties
- Extract reusable components to separate views
- Use @ViewBuilder for conditional content
- Implement PreferenceKey for cross-view communication

// State management
- Use @State for local view state
- Use @Shared for persistent storage
- Use @Environment for dependency injection
- Avoid @ObservableObject (per architecture requirement)
```

### 11.3 Async/Await Guidelines
```swift
// Network operations
- Always use async/await for network calls
- Implement proper cancellation with Task
- Use TaskGroup for concurrent operations
- Handle errors at appropriate levels

// UI updates
- Use @MainActor for UI state changes
- Perform network operations off main thread
- Show loading states during async operations
```

---

## 12. Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| App launch time | < 300ms | Time to UsersListView appearance |
| Memory usage | < 150MB | Peak during 30min session |
| Image load time | < 500ms | Album artwork 300x300 |
| API response time | < 2s | Weekly chart data |
| Cache hit ratio | > 80% | Image and API caches combined |
| CPU usage | < 20% | During normal scrolling |

---

## 13. Accessibility Requirements

### 13.1 VoiceOver Support
- All interactive elements have descriptive labels
- Album artwork includes artist and title in accessibility label
- Navigation buttons announce their action and state
- Play count information is properly conveyed

### 13.2 Dynamic Type
- All text scales from Accessibility Extra Small to Accessibility Extra Extra Extra Large
- Layouts adapt to larger text sizes
- Images scale appropriately with text
- Touch targets remain at least 44x44 points

### 13.3 Contrast & Visibility
- Maintain WCAG AA contrast ratios
- Dominant color backgrounds ensure text readability
- Loading states are clearly indicated
- Error states are prominently displayed

---

## 14. Success Criteria

### 14.1 Technical Acceptance
- [ ] All functional requirements (F1-F11) implemented and tested
- [ ] Zero crashes during normal usage flows
- [ ] Performance targets met on iPhone 15 Mini
- [ ] Accessibility validation passes
- [ ] Migration works from v1.3.1 with zero data loss

### 14.2 User Experience Validation
- [ ] App feels familiar to existing users
- [ ] New users can complete onboarding successfully
- [ ] All screenshots in Planning/screenshots are achievable
- [ ] Smooth animations and transitions throughout
- [ ] Offline functionality works as expected

### 14.3 Code Quality Gates
- [ ] All unit tests passing (minimum 80% coverage)
- [ ] No compiler warnings
- [ ] SwiftLint validation passes
- [ ] Documentation complete for public APIs
- [ ] Ready for TestFlight distribution

---

*This enhanced PRD provides comprehensive technical specifications extracted from the legacy Objective-C implementation, ensuring successful LLM-driven development with minimal ambiguity and maximum validation checkpoints.*