# Features/Root Directory

## App-Level Architecture
- `VinylogueApp.swift` - Main app entry point with testing infrastructure
- `RootStore.swift` - Central app state management with migration handling
- `AppModel.swift` - App-level navigation and feature coordination
- `RootView.swift` - Root UI coordinator managing app flow
- `AppView.swift` - Main navigation container

## Architecture Pattern
App Launch → Migration → Authentication → Main App

## Key Patterns
- **@Observable** for state management with @Shared for global state
- **Type-Safe Navigation** - Enum-based navigation with associated values
- **Migration-First Design** - Legacy data migration as first-class concern
- **Feature Integration** - Store creation in AppModel, view routing in AppView

## Critical Notes
- Uses Point-Free Sharing library with different storage strategies (AppStorage, FileStorage, InMemory)
- Comprehensive testing support with dependency injection and mock data
- Conditional UI rendering based on migration status and user authentication
- Type-safe navigation with `AppModel.Path` enum and associated values
- Global state management via SharedKeys.swift with appropriate storage strategies