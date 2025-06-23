# Core Views Directory

## Reusable UI Components
- `ReusableAlbumArtworkView.swift` - Album artwork display with loading states
- `AnimatedLoadingIndicator.swift` - Spinning vinyl record loading animation
- `EmptyStateView.swift` - Consistent empty state messaging
- `ErrorStateView.swift` - Standardized error display with retry
- `LastFMUsernameInputView.swift` - Username input with validation
- `LoadingButton.swift` - Button with integrated loading states
- `SectionHeaderView.swift` - Consistent section headers

## Design System
- **Colors** - Legacy-based, NO DARK MODE (use `Color+Vinylogue.swift`)
- **Typography** - AvenirNext fonts via `.f()` helper function
- **Layout** - Standard padding (24pt horizontal, 12-40pt vertical)

## Key Patterns
- `@State` for internal state, `@Binding` for parent-child communication
- TimelineView for smooth animations (AnimatedLoadingIndicator)
- Comprehensive accessibility labels and screen reader support
- Screenshot testing with pixelation processor for UI tests