# Features/UserManagement Directory

## User Management Features
- `OnboardingStore/View.swift` - First-time user setup with username validation
- `SettingsStore/View.swift` - App configuration and preferences
- `UsernameChangeStore/View.swift` - Username change with validation
- `AddFriendStore/View.swift` - Manual friend addition
- `EditFriendsStore/View.swift` - Friend list management with drag-and-drop
- `LicensesView.swift` - Legal/licenses display

## Architecture Pattern
Consistent **Store + View** pattern:
- `@Observable` stores for business logic and state
- `@Dependency` for service injection
- `@Shared` for global app state (user, friends, settings)
- SwiftUI views with clean separation of concerns

## Key Patterns
- **Username Validation** - Last.fm API validation before allowing access
- **Automatic Friend Import** - FriendsImporter integration during onboarding
- **Cyclic Settings** - Play count filter cycles through values (0,1,2,4,8,16,32)
- **Bulk Operations** - Drag-and-drop reordering and bulk selection for friends
- **State Synchronization** - Updates shared state with proper thread safety