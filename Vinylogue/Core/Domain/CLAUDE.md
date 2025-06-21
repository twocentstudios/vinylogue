# Domain Layer Architecture Guide

The Domain layer contains the core business logic, data models, and services that power the Vinylogue application. This layer is independent of UI concerns and focuses on the essential business rules and data structures.

## Architecture Overview

The Domain layer is organized into two main areas:
- **Models**: Core data structures, API responses, and legacy migration models
- **Services**: Business logic services for API communication, caching, and data processing

## Quick Navigation

### Looking for Data Models?
📂 **See [Models/CLAUDE.md](Models/CLAUDE.md)** for:
- User and Album data structures
- Last.fm API response models
- Legacy migration models  
- Shared state management keys
- Color extraction integration

### Looking for Business Services?
📂 **See [Services/CLAUDE.md](Services/CLAUDE.md)** for:
- Last.fm API client architecture
- Caching strategies and implementation
- Friends import service
- Legacy data migration service
- Dependency injection patterns

## Key Architectural Decisions

### 1. Data Model Design Philosophy
- **Codable-First**: All models implement `Codable` for JSON serialization
- **Swift Concurrency Ready**: All models conform to `Sendable` for thread safety
- **SwiftUI Optimized**: Models implement `Identifiable` and `Hashable` for efficient list rendering
- **Type Safety**: Computed properties convert API string values to appropriate types (Int, URL, etc.)

### 2. Service Architecture Patterns
- **Protocol-Based Design**: All services implement protocols for testability and dependency injection
- **Async/Await**: Modern Swift concurrency throughout the service layer
- **Error Handling**: Structured error types with user-friendly `LocalizedError` implementations
- **Caching Strategy**: Multi-layered caching using JSON serialization for type safety

### 3. Legacy Migration Strategy
- **One-Time Migration**: Handles transition from Objective-C NSCoding-based storage
- **Safe Execution**: Migration can be called multiple times without side effects
- **Comprehensive Logging**: Detailed logging for troubleshooting migration issues
- **Gradual Cleanup**: Legacy data removed only after successful migration

## Integration Patterns

### Model Usage in Views
```swift
// Models are designed for direct SwiftUI binding
struct AlbumRowView: View {
    let album: UserChartAlbum
    
    var body: some View {
        HStack {
            AsyncImage(url: album.detail?.imageURL)
            VStack(alignment: .leading) {
                Text(album.name)
                Text(album.artist)
            }
            Spacer()
            Text("\(album.playCount)")
        }
    }
}
```

### Service Integration with Stores
```swift
// Services integrate with TCA-style stores via dependency injection
@MainActor
@Observable
final class WeeklyAlbumsStore {
    @ObservationIgnored @Dependency(\.lastFMClient) private var lastFMClient
    @ObservationIgnored @Dependency(\.cacheManager) private var cacheManager
    
    func loadWeeklyChart() async {
        do {
            let response = try await lastFMClient.request(.userWeeklyAlbumChart(...))
            // Process response...
        } catch {
            // Handle error...
        }
    }
}
```

### Shared State Management
```swift
// Global app state is managed through typed shared keys
@Shared(.currentUser) var currentUsername: String?
@Shared(.curatedFriends) var curatedFriends: [User]
@Shared(.currentPlayCountFilter) var playCountFilter: Int
```

## Data Flow Architecture

### API Response Processing
```
Last.fm API → LastFMResponses → Domain Models → UI Display
     ↓              ↓               ↓            ↓
Raw JSON → Nested Structures → Flat Models → SwiftUI Views
```

### Caching Strategy
```
Network Request → Cache Check → API Call → Cache Store → Model Return
       ↓              ↓           ↓           ↓            ↓
   Cache Key → JSON Lookup → HTTP Request → JSON Save → Typed Model
```

### Legacy Migration Flow
```
App Launch → Migration Check → Legacy Data Load → Model Conversion → New Storage
     ↓              ↓               ↓                ↓              ↓
  RootStore → LegacyMigrator → NSKeyedArchiver → toUser() → SharedKeys
```

## Critical Patterns & Conventions

### 1. Model Conformances
Every domain model should implement:
- `Codable` for JSON serialization
- `Sendable` for Swift concurrency safety
- `Identifiable` for SwiftUI list performance
- `Hashable` for efficient comparisons and Set operations

### 2. API Response Handling
- Use computed properties for type conversion (String → Int)
- Handle nil values gracefully with sensible defaults
- Extract common patterns (imageURL, playCount) into reusable computed properties
- Map API naming conventions to Swift conventions via `CodingKeys`

### 3. Error Handling Strategy
- Implement `LocalizedError` for user-friendly error messages
- Map API error codes to semantic error types
- Provide fallback behavior when appropriate (cached data, placeholder content)
- Use structured error types rather than generic errors

### 4. Performance Considerations
- Lazy loading for expensive operations (color extraction)
- Caching strategies for network-derived data
- Background processing for non-critical operations
- Efficient data structures for large datasets

## Testing Approach

### Model Testing
- JSON encoding/decoding round-trip tests
- Edge case handling (nil values, malformed data)
- Computed property validation
- Legacy migration conversion testing

### Service Testing
- Mock implementations for all service protocols
- Comprehensive error scenario testing
- Cache behavior validation
- Network failure handling

## Extension Guidelines

### Adding New Models
1. Follow the established conformance pattern (`Codable`, `Sendable`, `Identifiable`, `Hashable`)
2. Add appropriate computed properties for common UI needs
3. Include comprehensive documentation with usage examples
4. Add to SharedKeys.swift if global state is needed

### Adding New Services
1. Define protocol first for testability
2. Implement dependency injection registration
3. Add proper error handling with `LocalizedError`
4. Consider caching strategy for network-derived data
5. Mark as `@MainActor` if UI integration is needed

### Modifying Existing Models
1. Maintain backward compatibility for stored data
2. Update migration logic if storage format changes
3. Test thoroughly with existing cached data
4. Update related computed properties and methods

This domain layer provides a solid foundation for the Vinylogue app's business logic, with clear separation of concerns and modern Swift patterns throughout.