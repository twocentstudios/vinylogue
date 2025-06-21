# Services Architecture Guide

This directory contains the core services that power the Vinylogue application. This guide explains the architecture, patterns, and best practices for working with these services.

## Service Overview

### 1. LastFMClient (`LastFMClient.swift`)
**Purpose**: Primary API client for communicating with the Last.fm Web Services API.

**Key Responsibilities**:
- HTTP requests to Last.fm endpoints with proper error handling
- Network availability monitoring using NWPathMonitor
- API response validation and error mapping
- Album info caching for performance optimization
- Response data cleaning (removes Last.fm promotional text)

**Key Patterns**:
```swift
// Dependency injection pattern
@Dependency(\.lastFMClient) private var lastFMClient

// Generic request method with proper error handling
func request<T: Codable>(_ endpoint: LastFMEndpoint) async throws -> T

// Cached album info with fallback to API
func fetchAlbumInfo(artist: String?, album: String?, mbid: String?, username: String?) async throws -> AlbumDetail
```

**Error Handling Strategy**:
- Maps Last.fm API error codes to semantic errors (userNotFound, serviceUnavailable, etc.)
- Handles network unavailability gracefully
- Provides user-friendly error messages via LocalizedError

### 2. CacheManager (`CacheManager.swift`)
**Purpose**: Generic, type-safe caching system using JSON serialization.

**Key Features**:
- Generic Codable storage: `store<T: Codable>(_ object: T, key: String)`
- Type-safe retrieval: `retrieve<T: Codable>(_ type: T.Type, key: String) -> T?`
- Automatic cache directory management in temporary directory
- Legacy compatibility via ChartCache wrapper

**Cache Architecture**:
```swift
// Main cache operations
await cacheManager.store(data, key: "user_data")
let cached: UserData? = try await cacheManager.retrieve(UserData.self, key: "user_data")

// Cache key building (see CacheKeyBuilder.swift)
let key = CacheKeyBuilder.albumInfo(artist: "Artist", album: "Album", username: "user")
```

**Threading**: Marked as `Sendable` for thread-safe usage across async contexts.

### 3. FriendsImporter (`FriendsImporter.swift`)
**Purpose**: Manages importing and processing friends data from Last.fm.

**Architecture**:
- `@Observable @MainActor` for SwiftUI integration
- State-driven loading with `FriendsLoadingState` enum
- Automatic sorting and deduplication of friends
- Integration with dependency injection system

**Usage Pattern**:
```swift
// Import friends with automatic state management
await friendsImporter.importFriends(for: username)

// Access loading state in SwiftUI
switch friendsImporter.friendsState {
case .loading: 
    ProgressView()
case .loaded(let friends): 
    FriendsList(friends: friends)
case .failed(let error): 
    ErrorView(error: error)
}
```

### 4. LegacyMigrator (`LegacyMigrator.swift`)
**Purpose**: Handles one-time migration from legacy Objective-C app data.

**Migration Process**:
1. Loads NSKeyedArchiver data from UserDefaults
2. Maps legacy User class to new User models
3. Migrates settings and preferences
4. Uses @Shared persistence for new data storage
5. Cleans up legacy data after successful migration

**Key Features**:
- Safe to call multiple times (checks migration completion status)
- Comprehensive logging for debugging migration issues
- Thread-safe using @MainActor and proper locking
- Graceful handling of corrupted or missing legacy data

## Dependency Injection Patterns

### Service Registration (`Dependencies+Vinylogue.swift`)
```swift
// Protocol-based dependency registration
extension LastFMClient: DependencyKey {
    static let liveValue: LastFMClientProtocol = LastFMClient()
    static let testValue: LastFMClientProtocol = MockLastFMClient()
    static let previewValue: LastFMClientProtocol = MockLastFMClient()
}

// Dependency property wrapper usage
@Dependency(\.lastFMClient) private var lastFMClient
@Dependency(\.cacheManager) private var cacheManager
```

### Testing Strategy
- All services implement protocols for easy mocking
- MockLastFMClient provides realistic test data
- CacheManager uses temporary directory for test isolation
- Comprehensive mock responses for all Last.fm endpoints

## Error Handling Conventions

### Error Types and Mapping
```swift
// Semantic error mapping from API codes
func mapLastFMError(code: Int, message: String) -> LastFMError {
    switch code {
    case 6: .userNotFound
    case 10: .invalidAPIKey
    case 11, 16: .serviceUnavailable
    default: .apiError(code: code, message: message)
    }
}

// User-friendly error descriptions
var errorDescription: String? {
    switch self {
    case .userNotFound: "User not found. Please check the username."
    case .networkUnavailable: "Network unavailable. Showing cached data."
    }
}
```

### Error Recovery Patterns
- Network errors fall back to cached data when available
- Invalid responses trigger appropriate user messaging
- Services continue functioning with degraded capabilities when possible

## Caching Strategies

### Cache Key Design (`CacheKeyBuilder.swift`)
```swift
// Hierarchical key structure
static func albumInfo(artist: String, album: String, username: String?) -> String {
    "album_info_\(normalize(artist))_\(normalize(album))_\(username ?? "none")"
}

// Timestamp-based keys for time-sensitive data
static func weeklyChart(username: String, from: Date, to: Date) -> String {
    "weekly_chart_\(username)_\(timestamp(from: from))_\(timestamp(from: to))"
}
```

### Cache Management
- Automatic cache directory creation and cleanup
- JSON-based storage for type safety and debugging
- Generic cache operations support any Codable type
- Legacy cache compatibility for smooth transitions

## API Client Configuration

### Last.fm Integration
```swift
// API configuration
private let baseURL = URL(string: "https://ws.audioscrobbler.com/2.0/")!
private let apiKey = Secrets.apiKey // Configure in Secrets.swift

// Endpoint definition with query parameter building
enum LastFMEndpoint {
    case userWeeklyAlbumChart(username: String, from: Date, to: Date)
    case albumInfo(artist: String?, album: String?, mbid: String?, username: String?)
    
    var queryItems: [URLQueryItem] { /* implementation */ }
}
```

### Network Monitoring
- Real-time network availability checking
- Graceful degradation when offline
- Automatic request queuing/retry could be added

## State Management Integration

### Shared State Pattern
```swift
// Type-safe shared keys (see SharedKeys.swift)
@Shared(.currentUser) var currentUsername: String?
@Shared(.curatedFriends) var curatedFriends: [User]
@Shared(.migrationCompleted) var migrationCompleted: Bool

// Thread-safe updates
$curatedFriends.withLock { $0 = newFriends }
```

### Observable Services
- Services that need UI binding use `@Observable @MainActor`
- State changes automatically trigger SwiftUI updates
- Clear separation between UI state and business logic

## Best Practices for Extending Services

### Adding New Services
1. **Create Protocol First**: Define clear interface for testability
2. **Implement DependencyKey**: Register with live, test, and preview values
3. **Use Proper Concurrency**: Mark as Sendable when appropriate, use @MainActor for UI-bound services
4. **Add Caching**: Use CacheManager for network-derived data
5. **Handle Errors Gracefully**: Implement LocalizedError with user-friendly messages

### Service Integration Checklist
- [ ] Protocol defined with clear responsibilities
- [ ] Dependency injection configured in Dependencies+Vinylogue.swift
- [ ] Error types implement LocalizedError
- [ ] Caching strategy implemented where appropriate
- [ ] Thread safety considered (@MainActor, Sendable)
- [ ] Test mocks created
- [ ] Logging added for debugging

### Common Patterns
```swift
// Service template
@Observable  // Only if UI state needed
@MainActor   // Only if UI integration required
final class NewService {
    @ObservationIgnored @Dependency(\.otherService) private var otherService
    @ObservationIgnored private let logger = Logger(subsystem: "com.twocentstudios.vinylogue", category: "NewService")
    
    // State properties
    var loadingState: LoadingState = .idle
    
    // Business logic methods
    func performAction() async throws {
        // Implementation with proper error handling
    }
}
```

## Legacy Migration Notes

### Migration Architecture
- One-time migration executed on app launch
- Safe re-execution (idempotent)
- Comprehensive logging for troubleshooting
- Gradual cleanup of legacy data

### Extending Migration
When adding new data types to migrate:
1. Add new legacy model classes to LegacyModels.swift
2. Implement NSCoding with correct legacy keys
3. Add migration logic to LegacyMigrator
4. Add conversion methods to transform legacy → new models
5. Update cleanup logic to remove legacy data

The services architecture provides a solid foundation for the Vinylogue app with proper separation of concerns, testability, and maintainability. Follow these patterns when extending or modifying services to maintain consistency and reliability.