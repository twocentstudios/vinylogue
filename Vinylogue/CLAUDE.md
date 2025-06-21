# Vinylogue Application

## Application Overview
SwiftUI-based Last.fm client for exploring weekly album charts with dynamic color theming.

## Architecture
```
Vinylogue/
├── Core/           # Foundation layer (infrastructure, services, reusable components)
└── Features/       # Business logic layer (user-facing functionality)
```

## Navigation
- **[Core/](Core/)** - Foundation infrastructure, services, reusable UI components
- **[Features/](Features/)** - App initialization, user management, music discovery features

## Critical Design Constraints
- **NO DARK MODE** - Light mode only, matching legacy Objective-C app design
- **Legacy Color System** - Must use predefined colors from `TCSVinylogueDesign.h`
- **SwiftUI + @Observable** - Modern architecture with Point-Free dependencies

## Technical Stack
- SwiftUI with @Observable state management
- Point-Free Dependencies and Sharing libraries
- Last.fm API integration with comprehensive caching
- Legacy migration from NSCoding to Codable

## Development Commands
```bash
xcodegen              # After adding/removing/renaming files
swiftformat .         # Format code before building
xcodebuild -quiet     # Build with quiet output
```