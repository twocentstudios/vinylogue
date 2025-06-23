# Vinylogue Application

## Overview
SwiftUI Last.fm client for weekly album charts with dynamic color theming.

## Architecture
- **Core/** - Foundation layer (infrastructure, services, reusable components)
- **Features/** - Business logic layer (user-facing functionality)

## Critical Constraints
- **NO DARK MODE** - Light mode only, matches legacy Objective-C design
- **Colors** - Use predefined colors from `Color+Vinylogue.swift`
- **Modern Stack** - SwiftUI + @Observable + Point-Free dependencies

## Development Commands
```bash
xcodegen          # After adding/removing/renaming files
swiftformat .     # Format code before building
xcodebuild -quiet # Build with quiet output
```

## Swift Package Dependencies

- **Nuke**
  - Advanced image loading and caching framework with powerful performance optimizations
  - [Documentation](DerivedData/Vinylogue/SourcePackages/checkouts/Nuke/Documentation/Nuke.docc/)
- **NukeUI** (part of Nuke)
  - SwiftUI components for declarative image loading with LazyImage and FetchImage
  - [Documentation](DerivedData/Vinylogue/SourcePackages/checkouts/Nuke/Documentation/NukeUI.docc/)
- **Sharing** (Point-Free)
  - Type-safe shared state management library for global app state persistence
  - [Documentation](DerivedData/Vinylogue/SourcePackages/checkouts/swift-sharing/Sources/Sharing/Documentation.docc/)
- **Dependencies** (Point-Free)
  - Dependency injection framework for testable and modular Swift applications
  - [Documentation](DerivedData/Vinylogue/SourcePackages/checkouts/swift-dependencies/Sources/Dependencies/Documentation.docc/)
  
## Code Architecture Reference

- Point-Free Co. SyncUps
    - https://uithub.com/pointfreeco/syncups?accept=text/html&maxTokens=50000&ext=swift