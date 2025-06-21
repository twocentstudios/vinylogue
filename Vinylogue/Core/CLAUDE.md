# Core Directory

## Core Layer Overview
Foundational components supporting the entire Vinylogue application.

## Subdirectories
- **[Domain/](Domain/)** - Business logic, data models, services
- **[Infrastructure/](Infrastructure/)** - Utilities, extensions, configuration
- **[Views/](Views/)** - Reusable UI components and design system

## Critical Design Constraints
- **NO DARK MODE** - App designed exclusively for light mode matching legacy design
- **Legacy Color System** - Must use predefined colors from `TCSVinylogueDesign.h`
- **AvenirNext Typography** - Exclusive font family via `.f()` helper system

## Key Architecture
- **SwiftUI + @Observable** - Modern state management with Point-Free Sharing library
- **Protocol-Oriented Services** - Dependency injection for testability
- **Type-Safe Patterns** - Codable + Sendable + Identifiable throughout

### 3. Data Flow Strategy
- **Unidirectional Data Flow**: Clear data dependencies and state updates
- **Multi-Layer Caching**: Memory → Disk → Network with intelligent invalidation
- **Swift Concurrency**: Async/await throughout with proper @MainActor usage
- **Type Safety**: Strongly typed models and API responses

## Integration Patterns

### Core Component Usage in Features
```swift
// Features use Core components consistently
struct FeatureView: View {
    @Bindable var store: FeatureStore
    
    var body: some View {
        VStack {
            SectionHeaderView("weekly albums")
            
            switch store.loadingState {
            case .loading:
                AnimatedLoadingIndicator(size: 40)
            case .empty:
                EmptyStateView(username: store.username)
            case .error(let error):
                ErrorStateView(error: error)
            case .loaded(let albums):
                LazyVStack {
                    ForEach(albums) { album in
                        AlbumRowView(album: album)
                    }
                }
            }
        }
    }
}
```

### Service Integration Pattern
```swift
// Features integrate with Core services via dependency injection
@MainActor
@Observable
final class FeatureStore {
    @ObservationIgnored @Dependency(\.lastFMClient) private var lastFMClient
    @ObservationIgnored @Dependency(\.cacheManager) private var cacheManager
    @ObservationIgnored @Shared(.currentUser) var currentUser: String?
    
    func performAction() async {
        let cacheKey = CacheKeyBuilder.feature(user: currentUser, id: "data")
        if let cached: DataType = try? await cacheManager.retrieve(DataType.self, key: cacheKey) {
            // Use cached data
        } else {
            // Load from API and cache
            let data = try await lastFMClient.request(.endpoint)
            await cacheManager.store(data, key: cacheKey)
        }
    }
}
```

### UI Theming Integration
```swift
// Features leverage Core color and typography systems
var body: some View {
    Text("Album Title")
        .font(.f(.medium, .title2))
        .foregroundColor(.primaryText)
        .background(Color.primaryBackground)
        .cornerRadius(4)
}
```

## Critical Infrastructure Components

### 1. Color System (NO DARK MODE)
- **Primary Colors**: `.primaryText` (dark blue), `.primaryBackground` (subtle white)
- **Legacy Colors**: Exact RGB matches to original app
- **Color Extraction**: Advanced album artwork color analysis for dynamic theming
- **Typography**: `.f(fontVariant, style)` system with AvenirNext family

### 2. Caching Architecture
- **Structured Keys**: `CacheKeyBuilder` for consistent cache key generation
- **Type-Safe Storage**: Generic `CacheManager` with Codable support
- **Multi-Layer Strategy**: Memory, temporary disk, and persistent storage
- **Smart Invalidation**: Based on user changes and data freshness

### 3. Image Pipeline
- **Nuke Integration**: Advanced image loading and caching
- **Color Extraction**: Sophisticated album artwork analysis
- **Placeholder System**: Branded vinyl record placeholders
- **Performance**: Background prefetching and concurrent loading

### 4. Testing Infrastructure
- **Environment Detection**: `isTesting` and `isScreenshotTesting` globals
- **Mock Services**: Comprehensive mock implementations with realistic data
- **Preview Support**: Rich SwiftUI previews for all components
- **Dependency Overrides**: Test-specific service implementations

## Development Workflow Integration

### For Adding New Features
1. **Models**: Add data models to `Core/Domain/Models/`
2. **Services**: Add business logic to `Core/Domain/Services/`
3. **UI Components**: Create reusable components in `Core/Views/`
4. **Infrastructure**: Add utilities to `Core/Infrastructure/` if needed
5. **Feature Implementation**: Build specific features using Core components

### For UI Development
1. **Design System**: Use existing components from `Core/Views/`
2. **Colors & Typography**: Reference `Core/Infrastructure/Color+Vinylogue.swift`
3. **Loading States**: Use `AnimatedLoadingIndicator`, `EmptyStateView`, `ErrorStateView`
4. **Testing**: Leverage `Core/Infrastructure/TestingUtilities.swift`

### For Service Development
1. **Protocol Definition**: Define service protocol in `Core/Domain/Services/Protocols/`
2. **Implementation**: Add service implementation in `Core/Domain/Services/`
3. **Dependency Registration**: Register in `Core/Infrastructure/Dependencies+Vinylogue.swift`
4. **Testing**: Create mock implementation for testing

## Performance & Optimization Patterns

### 1. Data Loading Strategy
- **Progressive Loading**: Essential data first, details loaded in background
- **Concurrent Limits**: Rate-limited concurrent requests (max 5 concurrent album details)
- **Prefetching**: Smart background loading for adjacent data
- **Cache-First**: Always check cache before network requests

### 2. UI Performance
- **Lazy Loading**: `LazyVStack`/`LazyHStack` for large lists
- **Image Optimization**: Nuke pipeline with size-appropriate loading
- **State Management**: Efficient `@Observable` usage with proper observation scoping
- **Animation**: Timeline-based animations for consistent performance

### 3. Memory Management
- **Weak References**: Proper memory management in async operations
- **Cache Limits**: Bounded caches with LRU eviction
- **Background Processing**: Off-main-thread work for expensive operations
- **Cleanup**: Proper store cleanup when features are dismissed

## Quality Assurance Patterns

### 1. Testing Strategy
- **Unit Tests**: Core business logic and model testing
- **UI Tests**: Screenshot testing for visual regression detection
- **Integration Tests**: Service integration and data flow validation
- **Preview Testing**: Comprehensive SwiftUI preview coverage

### 2. Error Handling
- **Structured Errors**: Typed error enums with `LocalizedError` conformance
- **Graceful Degradation**: Fallback to cached data when possible
- **User Communication**: Clear, actionable error messages
- **Recovery Mechanisms**: Retry logic and manual refresh options

### 3. Accessibility
- **Dynamic Type**: Responsive to user font size preferences
- **VoiceOver**: Comprehensive accessibility labels and hints
- **Color Contrast**: Sufficient contrast ratios throughout
- **Navigation**: Logical focus order and navigation patterns

This Core architecture provides a robust foundation for building maintainable, performant, and accessible iOS applications with clear separation of concerns and modern Swift patterns.