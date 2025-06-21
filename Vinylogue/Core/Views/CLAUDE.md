# Core UI Components Guide

This directory contains reusable UI components that form the foundation of the Vinylogue app's user interface. These components follow established design patterns and should be used consistently throughout the app.

## Design System Overview

### Color System
- **Primary Colors**: Based on legacy Vinylogue design (no dark mode support)
  - `primaryText`: Always `.vinylogueBlueDark` (RGB 15, 24, 46)
  - `primaryBackground`: Always `.vinylogueWhiteSubtle` (RGB 240, 240, 240)
  - `vinylogueGray`: `.vinylogueBluePeri` (RGB 220, 220, 220) for disabled states
  - `accent`: System accent color for interactive elements
  - `destructive`: Red for error states

### Typography System
- **Font Function**: Use `.f(fontVariant, textStyle)` or `.f(fontVariant, pointSize)`
- **Font Variants**: 
  - `.ultralight`: AvenirNext-Ultralight (for section headers, captions)
  - `.regular`: AvenirNext-Regular (for body text)
  - `.medium`: AvenirNext-Medium (for titles)
  - `.demiBold`: AvenirNext-Demibold (for emphasized text)
  - `.bold`, `.heavy`: Available for special emphasis

### Layout Patterns
- **Standard Padding**: 
  - Horizontal: 24pt for main content, 32pt for centered content
  - Vertical: 12pt for tight spacing, 24pt for section spacing, 40pt for major sections
- **Corner Radius**: 4pt for small elements, 6pt for larger elements
- **Shadows**: Subtle black opacity (0.1-0.25) with minimal offset

## Available Components

### 1. ReusableAlbumArtworkView
**Purpose**: Displays album artwork with consistent styling and loading states.

**Key Features**:
- Automatic image loading with Nuke/NukeUI
- Placeholder state with vinyl record design
- Screenshot testing support (pixelation for UI tests)
- Flexible sizing (fixed or aspect ratio)
- Optional shadow effects
- Completion callback for image loading

**Usage Patterns**:
```swift
// Fixed size for lists/rows
ReusableAlbumArtworkView.fixedSize(
    imageURL: album.imageURL,
    size: 80,
    cornerRadius: 4
)

// Flexible for detail views
ReusableAlbumArtworkView.flexible(
    imageURL: album.imageURL,
    cornerRadius: 6,
    showShadow: true,
    onImageLoaded: { image in ... }
)
```

**Design Principles**:
- Consistent vinyl record placeholder design
- Graceful error handling (shows placeholder on load failure)
- Automatic aspect ratio maintenance
- Testing-friendly with pixelation processor

### 2. AnimatedLoadingIndicator
**Purpose**: Animated vinyl record spinning animation for loading states.

**Key Features**:
- 12-frame animation sequence using image assets (loading01-loading12)
- Configurable size (default 40pt)
- TimelineView-based smooth animation
- 0.5-second animation duration

**Usage Patterns**:
```swift
AnimatedLoadingIndicator(size: 40)  // Small
AnimatedLoadingIndicator(size: 60)  // Medium  
AnimatedLoadingIndicator(size: 80)  // Large
```

**Integration**: Used within LoadingButton and standalone loading states.

### 3. EmptyStateView
**Purpose**: Consistent empty state messaging with user context.

**Key Features**:
- Large music note icon with hierarchical rendering
- Personalized messaging with username
- Centered layout with proper spacing
- Matches app typography and color scheme

**Usage Patterns**:
```swift
EmptyStateView(username: "ybsc")
```

**Design Principles**:
- Uses `.vinylogueBlueDark` for icon color
- Proper line spacing (2pt) for body text
- Centered multiline text alignment
- Top padding (60pt) for visual balance

### 4. ErrorStateView
**Purpose**: Standardized error display with contextual messaging.

**Key Features**:
- Triangle warning icon with hierarchical rendering
- Accepts `LastFMError` types for specific error messaging
- Consistent layout matching empty states
- Localized error descriptions

**Usage Patterns**:
```swift
ErrorStateView(error: .networkUnavailable)
ErrorStateView(error: .userNotFound)
ErrorStateView(error: .invalidResponse)
```

**Design Principles**:
- Same layout structure as EmptyStateView for consistency
- Uses system error descriptions when available
- Appropriate icon choice (exclamationmark.triangle)

### 5. LastFMUsernameInputView
**Purpose**: Specialized text input for Last.fm usernames with validation states.

**Key Features**:
- Music note prefix icon
- Clear button when text is present
- Focus state management with `@FocusState`
- Error display with validation messaging
- Accessibility support with labels and hints
- Automatic text corrections disabled
- Username content type for autofill

**Usage Patterns**:
```swift
LastFMUsernameInputView(
    username: $username,
    isValidating: $isValidating,
    errorMessage: errorMessage,
    showError: showError,
    accessibilityHint: "Enter your Last.fm username",
    onSubmit: { validateUsername() }
)
```

**State Management**:
- `@Binding var username: String` - Two-way text binding
- `@Binding var isValidating: Bool` - Loading state
- `@FocusState var isFocused: Bool` - Focus management

**Design Principles**:
- Gray background with opacity for subtle input field
- Destructive color for error messages
- Proper padding and spacing for touch targets
- Accessibility-first design

### 6. LoadingButton
**Purpose**: Button with integrated loading states and accessibility.

**Key Features**:
- Integrated AnimatedLoadingIndicator during loading
- Automatic state management (disabled when loading)
- Customizable titles for normal and loading states
- Accessibility labels and hints
- Dynamic background colors based on state

**Usage Patterns**:
```swift
LoadingButton(
    title: "Submit",
    loadingTitle: "submitting...",
    isLoading: isSubmitting,
    isDisabled: !isValid,
    accessibilityHint: "Submits the form",
    action: { submitForm() }
)
```

**State Colors**:
- Normal: `.accent` background
- Disabled/Loading: `.vinylogueGray.opacity(0.3)` background
- Text: `.vinylogueWhiteSubtle` normal, `.primaryText.opacity(0.6)` loading

### 7. SectionHeaderView
**Purpose**: Consistent section headers throughout the app.

**Key Features**:
- Ultralight font weight for elegant appearance
- Automatic lowercase text transformation
- Configurable top padding (default 40pt)
- Full-width left alignment
- Standard horizontal padding (24pt)

**Usage Patterns**:
```swift
SectionHeaderView("recent albums")
SectionHeaderView("friends", topPadding: 20)
```

**Design Principles**:
- Always lowercase for brand consistency
- Ultralight font weight for hierarchy
- Consistent padding for rhythm

## Component Composition Strategies

### 1. State Management Patterns
```swift
// Use @State for internal component state
@State private var isLoading = false

// Use @Binding for parent-child communication
@Binding var username: String

// Use @FocusState for focus management
@FocusState private var isFocused: Bool
```

### 2. Error Handling Patterns
```swift
// Graceful image loading
if let image = state.image {
    image.resizable().aspectRatio(contentMode: .fill)
} else if state.error != nil {
    placeholderView
} else {
    placeholderView
}
```

### 3. Accessibility Patterns
```swift
.accessibilityLabel("Last.fm username")
.accessibilityHint("Enter your Last.fm username")
.accessibilityLabel(isLoading ? "Loading" : title)
```

### 4. Animation Patterns
```swift
// TimelineView for continuous animations
TimelineView(.periodic(from: .now, by: animationDuration / Double(frameCount))) { timeline in
    // Animation logic
}

// State-based animations
.shadow(
    color: showShadow ? .black.opacity(0.2) : .clear,
    radius: showShadow ? 4 : 0
)
```

## Testing Support

### Screenshot Testing
- Components automatically handle screenshot testing mode
- `isScreenshotTesting` global variable available
- AlbumArtworkView applies pixelation processor during tests
- Testing utilities in `TestingUtilities.swift`

### Preview Support
- All components include comprehensive SwiftUI previews
- Multiple size variations shown in previews
- Dark/light background examples where relevant

## Integration Guidelines

### With App Architecture
- Components integrate with TCA (The Composable Architecture) stores
- Error types use `LastFMError` enum for consistency
- State management follows binding patterns
- Accessibility follows system conventions

### With Design System
- Always use `.f()` font function, never hardcoded fonts
- Use named colors (`.primaryText`, `.primaryBackground`, etc.)
- Follow established padding and spacing patterns
- Maintain consistency with legacy Vinylogue design

### Performance Considerations
- Lazy image loading with Nuke for album artwork
- Efficient animation using TimelineView
- Minimal state updates to prevent unnecessary rerenders
- Proper use of `@ViewBuilder` for conditional rendering

## Best Practices

1. **Consistency**: Always use existing components before creating new ones
2. **Accessibility**: Include proper labels, hints, and semantic markup  
3. **State Management**: Follow established binding patterns
4. **Error Handling**: Provide graceful fallbacks for all failure states
5. **Testing**: Support screenshot testing and provide comprehensive previews
6. **Performance**: Use lazy loading and efficient animations
7. **Typography**: Always use the `.f()` font system
8. **Colors**: Use named semantic colors from the design system
9. **Spacing**: Follow established padding and margin patterns
10. **Composition**: Build complex UIs by composing these base components

## Common Patterns

### Loading States
```swift
if isLoading {
    AnimatedLoadingIndicator(size: 40)
} else {
    // Content
}
```

### Empty/Error States
```swift
switch state {
case .loading:
    AnimatedLoadingIndicator()
case .empty:
    EmptyStateView(username: username)  
case .error(let error):
    ErrorStateView(error: error)
case .content(let data):
    // Content view
}
```

### Form Inputs
```swift
VStack(spacing: 12) {
    SectionHeaderView("account details")
    
    LastFMUsernameInputView(
        username: $username,
        isValidating: $isValidating,
        errorMessage: errorMessage,
        showError: showError,
        onSubmit: validateUsername
    )
    
    LoadingButton(
        title: "Save",
        isLoading: isSubmitting,
        isDisabled: !isValid,
        action: save
    )
}
```