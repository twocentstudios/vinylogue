# Features/Root Directory

## App-Level Architecture
- `VinylogueApp.swift` - Main app entry point with testing infrastructure
- `RootStore.swift` - Central app state management with migration handling
- `AppModel.swift` - App-level navigation and feature coordination
- `RootView.swift` - Root UI coordinator managing app flow
- `AppView.swift` - Main navigation container

## Architecture Pattern
```
App Launch → Migration → Authentication → Main App
```

## Key Patterns
- **@Observable** for state management with @Shared for global state
- **Type-Safe Navigation**: Enum-based navigation with associated values
- **Migration-First Design**: Legacy data migration as first-class concern
- **Feature Integration**: Store creation in AppModel, view routing in AppView

## Critical Notes
- Uses Point-Free Sharing library with different storage strategies (AppStorage, FileStorage, InMemory)
- Comprehensive testing support with dependency injection and mock data
- Conditional UI rendering based on migration status and user authentication

**State Management Patterns:**
```swift
@MainActor
@Observable
final class RootStore {
    @ObservationIgnored @Shared(.currentUser) var currentUsername: String?
    @ObservationIgnored @Shared(.migrationCompleted) var migrationCompleted
    
    var appModel = AppModel()  // Owns app-level navigation state
    var migrator = LegacyMigrator()  // Migration service
}
```

**Key Features:**
- Reactive user authentication state
- Asynchronous migration handling
- Error recovery mechanisms
- Computed properties for derived state (`hasCurrentUser`, `currentUser`)

### AppModel.swift
**App-level navigation and feature coordination**

**Key Responsibilities:**
- Navigation path management via `@Shared(.navigationPath)`
- Feature store lifecycle management
- Navigation binding and coordination
- Dependency injection for date/calendar services

**Navigation Architecture:**
```swift
enum Path: Hashable {
    case weeklyAlbums(WeeklyAlbumsStore)
    case albumDetail(AlbumDetailStore)
}
```

**Patterns:**
- Type-safe navigation with associated values
- Store binding lifecycle management
- Shared navigation state across app instances
- Feature store ownership and coordination

### RootView.swift
**Root UI coordinator and app flow controller**

**Key Responsibilities:**
- App flow state machine (migration → authentication → main app)
- Conditional UI rendering based on app state
- Migration error handling UI
- Root-level task coordination

**State Flow:**
```
Migration Check → User Authentication → Main App
     ↓               ↓                    ↓
MigrationView    OnboardingView      AppView
```

**UI Patterns:**
- Conditional rendering with `Group` and `if-let` patterns
- Task-based async initialization
- Alert-based error handling
- Preview support for different app states

### AppView.swift
**Main app navigation container**

**Key Responsibilities:**
- Primary navigation stack management
- Feature view routing and presentation
- Navigation destination configuration

**Navigation Implementation:**
```swift
NavigationStack(path: $model.path) {
    UsersListView(store: model.usersListStore)
        .navigationDestination(for: AppModel.Path.self) { path in
            // Type-safe routing to feature views
        }
}
```

## Global State Management

### Shared State System
The app uses Point-Free's Sharing library for type-safe global state:

**Defined in `/Users/ctrott/Code/vinylogue/Vinylogue/Core/Domain/Models/SharedKeys.swift`:**
- `.currentUser` - Current user authentication state (AppStorage)
- `.currentPlayCountFilter` - User preference for play count filtering (AppStorage)
- `.migrationCompleted` - Migration completion tracking (AppStorage)
- `.curatedFriends` - User's friend list (FileStorage)
- `.navigationPath` - App navigation state (InMemory)

### Storage Strategies
- **AppStorage**: User preferences and authentication
- **FileStorage**: Persistent user data (friends list)
- **InMemory**: Transient app state (navigation)

## Dependency Injection

### Point-Free Dependencies Integration
- Uses `@Dependency` for service injection
- Supports dependency overrides for testing
- Provides standard dependencies (date, calendar, etc.)

### Testing Dependencies
- `prepareDependencies` for test-specific overrides
- In-memory storage for test isolation
- Mock date providers for deterministic testing

## App Lifecycle Management

### Initialization Flow
1. **App Launch** → `VinylogueApp.init()`
2. **Test Setup** → `setUpForUITest()` (if testing)
3. **Root View** → `RootView` with `RootStore`
4. **Migration** → `store.performMigration()` via `.task`
5. **Authentication Check** → Route to onboarding or main app
6. **Main App** → `AppView` with navigation

### State Transitions
```
App Launch → Migration → Authentication → Main App
     ↓           ↓            ↓             ↓
Initialize → Migrate → Check User → Navigate
```

## Navigation Architecture

### Hierarchical Navigation
- **Root Level**: Migration and authentication flow
- **App Level**: Main navigation stack with typed paths
- **Feature Level**: Individual feature navigation

### Type-Safe Routing
- `AppModel.Path` enum for compile-time safety
- Associated values carry feature stores
- Centralized navigation state management

## Testing Infrastructure

### UI Testing Support
- Environment-based test configuration
- Screenshot testing with deterministic data
- Dependency injection for test scenarios

### Test Data Management
- Mock user data for screenshots
- Overridable dependencies for isolation
- In-memory storage for test runs

## Integration Patterns

### Feature Integration
Features integrate at the app level through:
1. **Store Creation**: Feature stores created in `AppModel`
2. **Navigation Registration**: Paths registered in `AppModel.Path`
3. **View Routing**: Views registered in `AppView.navigationDestination`
4. **State Binding**: Optional binding setup in `AppModel.bind()`

### Service Integration
Services integrate through:
1. **Dependency Registration**: Services registered with Dependencies
2. **Shared State**: Global state via Sharing library
3. **Root Services**: App-wide services owned by `RootStore`

## Best Practices

### Adding New Features
1. Create feature store and views in appropriate feature directory
2. Add navigation case to `AppModel.Path`
3. Register navigation destination in `AppView`
4. Add any needed shared state keys to `SharedKeys.swift`
5. Consider binding needs in `AppModel.bind()`

### State Management
- Use `@Shared` for global state that persists across app launches
- Use `@Observable` for local feature state
- Prefer computed properties for derived state
- Use appropriate storage strategies (AppStorage, FileStorage, InMemory)

### Testing
- Override dependencies for test scenarios
- Use in-memory storage for test isolation
- Provide mock data through dependency system
- Support both unit testing and UI testing patterns

## Dependencies

### External Libraries
- **SwiftUI**: UI framework
- **Dependencies**: Dependency injection
- **Sharing**: Global state management
- **Nuke**: Image loading and caching

### Internal Dependencies
- Core domain models (User, etc.)
- Feature stores and views
- Shared utilities and services
- Testing utilities

This architecture provides a solid foundation for a modular, testable, and maintainable SwiftUI application with proper separation of concerns and modern Swift patterns.