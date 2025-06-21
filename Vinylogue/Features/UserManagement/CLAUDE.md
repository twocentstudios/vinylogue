# User Management Features Architecture Guide

This directory contains the user management features of the Vinylogue app, including onboarding, settings, username changes, and friend management. This guide documents the patterns and architecture used for building user-facing features in the app.

## Architecture Overview

### Store + View Pattern
All user management features follow a consistent **Store + View** architecture pattern:
- **Store**: `@Observable` class containing business logic, state management, and API interactions
- **View**: SwiftUI view that presents the UI and binds to the store's state
- **Dependencies**: Stores use `@Dependency` for injecting services like `lastFMClient`
- **Shared State**: Global app state is managed via `@Shared` from the Sharing library

### Key Dependencies
- `Dependencies`: Dependency injection framework for services
- `Sharing`: Global shared state management across the app
- `SwiftUI`: UI framework with modern declarative patterns

## Feature Architecture Patterns

### 1. Onboarding Flow (OnboardingStore + OnboardingView)

**Purpose**: First-time user setup and username validation

**Key Patterns**:
- **Username Validation**: Validates Last.fm usernames via API before allowing app access
- **Global State Updates**: Updates `@Shared(.currentUser)` and `@Shared(.curatedFriends)` 
- **Friend Import**: Automatically imports friends during onboarding via `FriendsImporter`
- **Error Handling**: Comprehensive error states with haptic feedback
- **Focus Management**: Auto-focuses text field on appear with delay
- **Loading States**: Shows validation progress with loading button

**State Management**:
```swift
var username = ""
var isValidating = false
var errorMessage: String?
var showError = false
```

**Integration Pattern**:
- Calls `lastFMClient.request(.userInfo(username:))` for validation
- Updates global shared state on success
- Imports friends automatically after validation

### 2. Settings Management (SettingsStore + SettingsView)

**Purpose**: App configuration and user preferences

**Key Patterns**:
- **Sectioned UI**: Uses `LazyVStack` with sections and custom headers
- **Cyclic Settings**: Play count filter cycles through predefined values (0, 1, 2, 4, 8, 16, 32)
- **External Actions**: Handles mail composition, app store rating, web links
- **Sheet Presentation**: Uses multiple `@State` booleans for different sheet types
- **Custom Button Styles**: `SettingsRowButtonStyle` for consistent interactive feedback

**Settings Categories**:
- **Play Count Filter**: Configurable album filtering by play count
- **User Management**: Username changes
- **Support**: Bug reporting, app store rating, licenses
- **About**: Developer links and contact info
- **Data Source**: Last.fm attribution

**Integration Pattern**:
- Direct shared state binding: `@Shared(.currentPlayCountFilter)`
- Mail composition via `MFMailComposeViewController`
- External URL opening via `UIApplication.shared.open()`

### 3. Username Change (UsernameChangeStore + UsernameChangeView)

**Purpose**: Allow users to change their Last.fm username

**Key Patterns**:
- **Pre-population**: Loads current username on view appear
- **Validation Before Save**: Same validation logic as onboarding
- **State Reset**: Clears friends list when username changes
- **Dismissal on Success**: Auto-dismisses sheet after successful change
- **Form Validation**: Disables save button until valid input

**State Management**:
```swift
var newUsername = ""
var isValidating = false
var validationError: String?
var isValid = false
var showError = false
```

**Integration Pattern**:
- Validates via Last.fm API before saving
- Updates `@Shared(.currentUser)` and clears `@Shared(.curatedFriends)`
- Returns boolean success status for view dismissal

### 4. Friend Management (AddFriendStore/View + EditFriendsStore/View)

**Purpose**: Manage user's curated friends list

#### Add Friend Feature
**Key Patterns**:
- **Callback Pattern**: Store takes `onFriendAdded` callback for decoupled communication
- **Duplicate Prevention**: Checks for existing friends and prevents self-addition
- **User Object Creation**: Builds complete `User` objects from API responses
- **Success Feedback**: Uses `friendAdded` trigger for sensory feedback

#### Edit Friends Feature
**Key Patterns**:
- **Multi-Modal Interface**: Import from Last.fm + manual addition + editing
- **Selection Management**: Bulk selection with select all/none functionality
- **Reordering**: Drag-and-drop reordering with `onMove`
- **Bulk Operations**: Delete multiple selected friends
- **State Synchronization**: Maintains selection state during list modifications
- **Dependency Injection**: Creates child stores with `withDependencies(from: self)`

**State Management**:
```swift
var editableFriends: [User] = []
var selectedFriends: Set<String> = []
var addFriendStore: AddFriendStore?
```

## Common UI Patterns

### 1. Form Input Pattern
- **Reusable Component**: `LastFMUsernameInputView` for username input
- **Focus Management**: `@FocusState` for keyboard control
- **Loading Buttons**: `LoadingButton` component with loading/disabled states
- **Error Alerts**: Consistent alert presentation with refocus behavior

### 2. Navigation Patterns
- **Modal Presentation**: Full-screen modals with NavigationView
- **Sheet Presentation**: Settings and secondary features use sheets
- **Toolbar Management**: Consistent cancel/save/done button placement
- **Title Styling**: Custom toolbar titles with brand colors

### 3. Error Handling
- **Haptic Feedback**: `UIImpactFeedbackGenerator` for error states
- **Specific Error Messages**: Tailored messages for different API errors
- **Error Recovery**: Focus management after error dismissal
- **Network Awareness**: Different messages for network vs API errors

### 4. Loading States
- **Loading Indicators**: Custom `AnimatedLoadingIndicator` component
- **Button States**: Loading buttons disable interaction during operations
- **Progress Feedback**: Loading titles and accessibility labels

## Shared State Integration

### Global State Keys
- `@Shared(.currentUser)`: Current user's Last.fm username
- `@Shared(.curatedFriends)`: User's friend list
- `@Shared(.currentPlayCountFilter)`: Play count filtering preference

### State Update Patterns
```swift
// Safe concurrent updates
$sharedState.withLock { $0 = newValue }

// Reader access
@SharedReader(.currentUser) var currentUsername: String?
```

## Service Integration

### Last.fm API Client
- **Dependency Injection**: `@Dependency(\.lastFMClient)`
- **Async/Await**: Modern concurrency for API calls
- **Error Handling**: Structured error types (`LastFMError`)
- **Request Types**: Typed API endpoints (`.userInfo(username:)`)

### Friends Import Service
- **External Service**: `FriendsImporter` for Last.fm friends
- **State Management**: Loading/loaded/error states
- **Deduplication**: Filters out existing friends

## Accessibility & User Experience

### Accessibility
- **Labels & Hints**: Comprehensive accessibility support
- **Dynamic Type**: Responsive to system font sizing
- **VoiceOver**: Proper semantic structure

### User Feedback
- **Sensory Feedback**: Haptic feedback for actions and state changes
- **Visual Feedback**: Loading states, selection states, pressed states
- **Error Communication**: Clear, actionable error messages

### Performance
- **MainActor**: All stores are `@MainActor` for UI thread safety
- **Async Operations**: Non-blocking API calls with proper error handling
- **State Observation**: Efficient SwiftUI observation with `@Observable`

## Testing Patterns

### Preview Support
- All views include SwiftUI previews
- Preview data setup for complex states
- Dark mode and accessibility previews
- Multiple device size previews

### Store Testing
- Stores are designed for testability with dependency injection
- State changes are observable
- Async operations return success/failure states

## File Organization

```
UserManagement/
├── OnboardingStore.swift          # First-time user setup
├── OnboardingView.swift
├── SettingsStore.swift            # App configuration
├── SettingsView.swift
├── UsernameChangeStore.swift      # Username modification
├── UsernameChangeView.swift
├── AddFriendStore.swift           # Individual friend addition
├── AddFriendView.swift
├── EditFriendsStore.swift         # Friends list management
├── EditFriendsView.swift
└── LicensesView.swift             # Legal/license display
```

## Key Takeaways for Future Development

1. **Consistent Architecture**: Always pair Store (business logic) with View (presentation)
2. **Shared State**: Use `@Shared` for global app state, local `@State` for view-specific state
3. **Error Handling**: Provide specific, actionable error messages with haptic feedback
4. **Loading States**: Always show loading feedback for async operations
5. **Accessibility**: Include labels, hints, and dynamic type support
6. **User Feedback**: Use sensory feedback for state changes and user actions
7. **Navigation**: Modal sheets for secondary features, full screens for primary flows
8. **Validation**: Validate user input before API calls and state updates
9. **Focus Management**: Control keyboard focus for better user experience
10. **Dependency Injection**: Use the Dependencies framework for testable, modular code

This architecture provides a solid foundation for building user-facing features that are maintainable, testable, and provide excellent user experience.