# Features Directory

## Features Layer Overview
Main user-facing functionality implementing business requirements and user experience flows.

## Subdirectories
- **[Root/](Root/)** - App-level architecture, navigation, lifecycle
- **[UserManagement/](UserManagement/)** - Onboarding, settings, account management
- **[Main/](Main/)** - Core music discovery features (charts, albums, users)

## Architecture Pattern
Consistent **Store + View** pattern across all features:
- `@Observable` stores for business logic and state management
- `@Dependency` for service injection
- `@Shared` for global app state (navigation, user, friends)
- SwiftUI views with clean separation of concerns

## Cross-Feature Integration
- **Navigation**: Shared `navigationPath` for deep linking and feature coordination
- **State**: Global shared state for user data, friends, and settings
- **Communication**: Callback patterns for decoupled feature interaction
    @ObservationIgnored @Shared(.globalState) var globalState
    
    // Actions
    func loadData() async {
        loadingState = .loading
        do {
            data = try await service.fetchData()
            loadingState = .loaded
        } catch {
            loadingState = .failed(error)
        }
    }
}

// View: UI presentation and user interaction
struct FeatureView: View {
    @Bindable var store: FeatureStore
    
    var body: some View {
        VStack {
            switch store.loadingState {
            case .loading: LoadingView()
            case .loaded: ContentView(data: store.data)
            case .failed(let error): ErrorView(error: error)
            }
        }
        .task { await store.loadData() }
    }
}
```

### 2. Navigation Integration
Features integrate with app-wide navigation through shared state:

```swift
// Navigation path management
@Shared(.navigationPath) var navigationPath: [AppModel.Path]

// Type-safe navigation
func navigateToFeature() {
    let featureStore = FeatureStore()
    navigationPath.append(.feature(featureStore))
}
```

### 3. State Management Strategy
- **Local State**: Feature-specific state in individual stores
- **Shared State**: Global app state via `@Shared` keys
- **Reactive Updates**: SwiftUI observation for automatic UI updates
- **Persistence**: Appropriate storage strategies (AppStorage, FileStorage, InMemory)

## Feature Integration Patterns

### Data Flow Between Features
```
Root Layer: App State & Navigation
    ↓
UserManagement: Authentication & Settings
    ↓
Main Features: Music Discovery & Display
    ↓
Core Services: API & Caching
```

### Cross-Feature Communication
- **Shared State**: Global user preferences and authentication
- **Navigation Events**: Type-safe routing between features
- **Service Layer**: Shared business logic via dependency injection
- **Event Broadcasting**: State changes trigger reactive updates

## Performance Optimization Strategies

### 1. Data Loading Patterns
- **Progressive Loading**: Essential data first, details in background
- **Caching Strategy**: Multi-layer caching with smart invalidation
- **Prefetching**: Background loading for improved user experience
- **Concurrent Loading**: Rate-limited parallel requests

### 2. UI Performance
- **Lazy Loading**: Efficient list rendering with LazyVStack/LazyHStack
- **Image Optimization**: Smart image loading and caching
- **State Observation**: Scoped observation to minimize unnecessary updates
- **Animation Performance**: Timeline-based animations for consistency

### 3. Memory Management
- **Store Lifecycle**: Proper cleanup when features are dismissed
- **Weak References**: Prevent retain cycles in async operations
- **Cache Bounds**: Limited cache sizes with appropriate eviction
- **Background Processing**: CPU-intensive work off the main thread

## User Experience Patterns

### 1. Loading States
Consistent loading state management across all features:
- **Initialized**: Before any data loading begins
- **Loading**: Active network requests with progress indicators
- **Loaded**: Successfully populated with data
- **Failed**: Error states with recovery options

### 2. Error Handling
- **Graceful Degradation**: Fallback to cached data when possible
- **User-Friendly Messages**: Clear, actionable error communication
- **Recovery Options**: Retry mechanisms and manual refresh
- **Haptic Feedback**: Sensory feedback for state changes

### 3. Navigation Patterns
- **Hierarchical**: Clear parent-child relationships
- **Modal Presentation**: Settings and secondary features
- **Deep Navigation**: Direct linking to specific content
- **Back Navigation**: Proper navigation stack management

## Testing & Quality Assurance

### 1. Feature Testing Strategy
- **Store Testing**: Business logic validation with mock dependencies
- **UI Testing**: Screenshot testing for visual regression detection
- **Integration Testing**: Cross-feature workflows and data flow
- **Accessibility Testing**: VoiceOver and dynamic type support

### 2. Preview Support
Comprehensive SwiftUI previews for all features:
- **Multiple States**: Loading, loaded, error, and empty states
- **Different Data**: Various content scenarios and edge cases
- **Device Sizes**: Different screen sizes and orientations
- **Accessibility**: High contrast and large text scenarios

### 3. Mock Data & Testing
- **Realistic Mock Data**: Production-like test data for previews
- **Dependency Overrides**: Test-specific service implementations
- **Screenshot Testing**: Consistent visual testing across features
- **Environment Variables**: Test configuration via environment

## Development Guidelines

### Adding New Features
1. **Architecture**: Follow Store-View pattern with proper state management
2. **Navigation**: Add navigation cases to `AppModel.Path` enum
3. **Dependencies**: Use dependency injection for services and shared state
4. **UI Components**: Leverage Core UI components for consistency
5. **Error Handling**: Implement comprehensive error states and recovery
6. **Testing**: Add appropriate unit tests, UI tests, and previews

### Modifying Existing Features
1. **Backward Compatibility**: Maintain existing navigation and state patterns
2. **State Migration**: Handle changes to shared state gracefully
3. **UI Consistency**: Maintain design system patterns and accessibility
4. **Performance**: Consider impact on caching and loading strategies
5. **Testing**: Update tests and previews to reflect changes

### Cross-Feature Integration
1. **Shared State**: Use appropriate shared keys for global state
2. **Service Layer**: Leverage existing services before creating new ones
3. **Navigation**: Integrate with existing navigation patterns
4. **UI Components**: Reuse Core components for consistency
5. **Data Models**: Extend existing models rather than duplicating

## Key Feature Capabilities

### Root Features
- App lifecycle management and initialization
- Global state management and migration
- Navigation coordination between features
- Testing infrastructure and configuration

### User Management Features
- New user onboarding with Last.fm validation
- Settings and preferences management
- Friend list curation and management
- Username changes with validation

### Main Features
- Weekly album chart exploration with year navigation
- Rich album detail views with dynamic color theming
- User selection and friend management
- Performance-optimized data loading and caching

## Integration with Core Layer

Features build upon Core infrastructure:
- **Domain Models**: User, Album, WeeklyChart data structures
- **Services**: LastFMClient, CacheManager, FriendsImporter
- **UI Components**: Reusable views for consistent user experience
- **Infrastructure**: Color system, caching, image processing

This Features architecture provides a scalable foundation for building rich, performant music discovery experiences while maintaining code quality, testability, and user experience consistency.