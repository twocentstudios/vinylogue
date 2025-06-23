# Services Directory

## Files
- `LastFMClient.swift` - Last.FM API client with network monitoring and caching
- `CacheManager.swift` - Generic JSON-based caching system
- `FriendsImporter.swift` - Observable service for importing friends from Last.fm
- `LegacyMigrator.swift` - One-time migration from NSKeyedArchiver to new format

## Key Patterns
- **Dependency Injection** - Swift Dependencies framework with protocol-based design
- **Error Handling** - Semantic error mapping with LocalizedError descriptions
- **Async/Await** - Modern concurrency with Sendable conformance throughout
- **State Management** - @Observable/@MainActor for UI, @Shared for persistence

## Critical Notes
- LastFMClient includes network monitoring and automatic album info caching
- CacheManager stores in temporary directory with type-safe JSON operations
- FriendsImporter updates @Shared state for reactive UI updates
- LegacyMigrator handles NSKeyedArchiver → Codable conversion safely
- All services implement protocols for testability with comprehensive mocks
- Error types implement LocalizedError with user-friendly messages
- Thread-safe with @MainActor and Sendable conformance