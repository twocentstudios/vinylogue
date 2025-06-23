# Features/Root Directory

## App-Level Architecture
- `VinylogueApp.swift` - Main app entry point with testing infrastructure
- `RootStore.swift` - Central app state management coordinating child stores
- `RootView.swift` - Root UI coordinator with reactive state transitions
- `MigrationStore.swift` - Dedicated migration logic with error handling
- `MigrationView.swift` - Migration UI with alert presentation
- `AppStore.swift` - App-level navigation and feature coordination
- `AppView.swift` - Main navigation container

## Architecture Pattern
App Launch → Migration → Onboarding → Main App

## Key Patterns
- **Reactive State Management** - RootStore coordinates child store lifecycle
- **Store + View Pattern** - Each feature has dedicated store and view pair
- **Type-Safe Navigation** - Enum-based navigation with associated values
- **Clean Separation** - Migration, onboarding, and app logic isolated
- **State-Driven UI** - Views react to store state changes automatically

## State Flow
- **Migration**: `MigrationStore` handles legacy data migration with error alerts
- **Onboarding**: `OnboardingStore` manages user setup and validation
- **Main App**: `AppStore` coordinates navigation and feature interaction
- **Coordination**: `RootStore.updateState()` manages store lifecycle based on shared state

## Critical Notes
- Uses Point-Free Sharing library with different storage strategies (AppStorage, FileStorage, InMemory)
- Reactive state updates via `onChange` modifiers in RootView
- Type-safe navigation with `AppStore.Path` enum and associated values
- Clean store lifecycle management prevents memory leaks and state conflicts