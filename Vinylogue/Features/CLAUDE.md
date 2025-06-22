# Features Directory

## Overview
Main user-facing functionality implementing business requirements and user experience flows.

## Subdirectories
- **Root/** - App-level architecture, navigation, lifecycle
- **UserManagement/** - Onboarding, settings, account management
- **Main/** - Core music discovery features (charts, albums, users)

## Architecture Pattern
Consistent **Store + View** pattern across all features:
- `@Observable` stores for business logic and state management
- `@Dependency` for service injection
- `@Shared` for global app state (navigation, user, friends)
- SwiftUI views with clean separation of concerns

## Store Creation and Navigation Rules

### Sheet-Based Navigation
**Pattern**: Parent stores create optional child stores for modal presentations

**Rules**:
1. **Parent Store**: Creates optional child store property (`var childStore: ChildStore?`)
2. **Parent Store**: Provides method to create child store (`func showChild() { childStore = ChildStore() }`)
3. **Parent View**: Uses `sheet(item: $store.childStore)` modifier
4. **Child View**: Accepts store as parameter (`@Bindable var store: ChildStore`)
5. **Child Store**: Must conform to `Identifiable` (class identity-based)
6. **Dependency Injection**: Use `withDependencies(from: self)` only if parent has `@Dependency` vars

**Example**:
```swift
// Parent Store
final class ParentStore {
    var childStore: ChildStore?
    func showChild() { childStore = ChildStore() }
}

// Parent View
.sheet(item: $store.childStore) { childStore in
    ChildView(store: childStore)
}

// Child Store
final class ChildStore: Identifiable { }

// Child View
struct ChildView: View {
    @Bindable var store: ChildStore
}
```

### Stack-Based Navigation
**Pattern**: Parent stores create child stores and append to shared navigation path

**Rules**:
1. **Parent Store**: Creates child store directly (`let childStore = ChildStore(params)`)
2. **Parent Store**: Appends to navigation path (`navigationPath.append(.child(childStore))`)
3. **Navigation Setup**: Uses `NavigationStack(path:)` with enum-based paths
4. **Destination Handling**: Uses `.navigationDestination(for:)` to route to child views
5. **Child View**: Accepts store as parameter (`@Bindable var store: ChildStore`)
6. **Dependency Injection**: Use `withDependencies(from: self)` if parent has `@Dependency` vars

**Example**:
```swift
// Parent Store
final class ParentStore {
    func navigateToChild() {
        let childStore = ChildStore()
        navigationPath.append(.child(childStore))
    }
}

// Navigation Setup
NavigationStack(path: $navigationPath) {
    ParentView()
        .navigationDestination(for: Path.self) { path in
            switch path {
            case .child(let store): ChildView(store: store)
            }
        }
}
```

### Key Principles
- **No Self-Creation**: Views must NEVER create their own stores (except VinylogueApp)
- **Parent Ownership**: Only parent stores create child stores
- **Identifiable**: All stores used in sheets must conform to `Identifiable`
- **Dependency Context**: Use `withDependencies(from: self)` when parent has dependencies
- **Class Identity**: Identifiable conformance based on class identity (`===`)

## Cross-Feature Integration
- **Navigation** - Shared `navigationPath` for deep linking and coordination
- **State** - Global shared state for user data, friends, and settings
- **Communication** - Callback patterns for decoupled feature interaction