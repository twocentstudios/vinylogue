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

## Cross-Feature Integration
- **Navigation** - Shared `navigationPath` for deep linking and coordination
- **State** - Global shared state for user data, friends, and settings
- **Communication** - Callback patterns for decoupled feature interaction