# Vinylogue iOS Application Architecture Guide

This is the complete architectural documentation for the Vinylogue iOS application - a Last.fm client that helps users explore their weekly album charts across different time periods. This guide provides a comprehensive overview of the application's structure and development patterns.

## 🏗️ Application Overview

Vinylogue is a SwiftUI-based iOS application that integrates with the Last.fm API to provide rich music discovery experiences. The app allows users to:
- Browse weekly album charts from different years
- Explore album details with dynamic color theming
- Manage friends and compare listening habits  
- Navigate through historical music data with intuitive interfaces

## 📁 High-Level Architecture

The application follows a layered architecture pattern with clear separation of concerns:

```
Vinylogue/
├── Core/           # Foundation layer - infrastructure, services, and reusable components
├── Features/       # Business logic layer - user-facing functionality
├── Models/         # (Legacy - being migrated to Core/Domain/Models)
└── Resources/      # Assets, images, and application resources
```

## 🎯 Quick Navigation by Development Task

### 🏛️ Understanding Overall Architecture
📂 **Start with [Core/CLAUDE.md](Core/CLAUDE.md)** for:
- Foundation infrastructure and services
- Reusable UI component library
- Color system and design patterns (NO DARK MODE)
- Caching strategies and dependency injection

### 🚀 Working on App-Level Features
📂 **See [Features/CLAUDE.md](Features/CLAUDE.md)** for:
- App initialization and navigation patterns
- User management and authentication flows
- Core music discovery features
- Feature integration patterns

### 📊 Building Data Models or API Integration
📂 **See [Core/Domain/CLAUDE.md](Core/Domain/CLAUDE.md)** for:
- Last.fm API integration patterns
- Data models and type definitions
- Service architecture and business logic
- Legacy migration strategies

### 🎨 Designing User Interface Components
📂 **See [Core/Views/CLAUDE.md](Core/Views/CLAUDE.md)** for:
- Reusable UI component library
- Design system and typography patterns
- Loading, empty, and error state components
- Accessibility and testing guidelines

## 🎨 Critical Design System Information

### Visual Design Philosophy
- **Legacy Matching**: All visual elements exactly match the original Objective-C Vinylogue app
- **NO DARK MODE SUPPORT**: The application is designed exclusively for light mode
- **Color Consistency**: Uses predefined color palette from legacy `TCSVinylogueDesign.h`
- **Typography**: AvenirNext font family exclusively via the `.f()` helper system

### Core Design Tokens
```swift
// Primary colors (always light mode)
Color.primaryText        // Dark blue: RGB(15, 24, 46)
Color.primaryBackground  // Subtle white: RGB(240, 240, 240)
Color.vinylogueGray     // Light gray: RGB(220, 220, 220)

// Typography system
Font.f(.ultralight, .title)   // AvenirNext-Ultralight with dynamic sizing
Font.f(.regular, 16)          // AvenirNext-Regular with fixed sizing
```

## 🏗️ Architectural Patterns

### 1. State Management Strategy
- **SwiftUI + Observable**: Modern reactive state management with `@Observable`
- **Global State**: Point-Free's Sharing library for app-wide state (`@Shared`)
- **Local State**: Feature-specific state management in individual stores
- **Type Safety**: Strongly typed shared keys for consistent state access

### 2. Dependency Injection
- **Protocol-Based**: All services implement protocols for testability
- **Point-Free Dependencies**: Modern dependency injection framework
- **Service Registration**: Centralized dependency configuration
- **Testing Support**: Mock implementations for all services

### 3. Data Flow Architecture
```
UI Layer (SwiftUI Views)
    ↓
Feature Stores (@Observable)
    ↓
Domain Services (Protocols)
    ↓
Infrastructure (Caching, Network)
    ↓
External APIs (Last.fm)
```

### 4. Navigation Architecture
- **Type-Safe Navigation**: Strongly typed navigation paths with associated values
- **Shared Navigation State**: Global navigation state via `@Shared(.navigationPath)`
- **Store Lifecycle**: Proper store management during navigation transitions
- **Deep Linking**: Support for direct navigation to specific content

## 🚀 Development Workflow Patterns

### For New Feature Development
1. **Models**: Define data structures in `Core/Domain/Models/`
2. **Services**: Add business logic to `Core/Domain/Services/`
3. **Infrastructure**: Add utilities to `Core/Infrastructure/` if needed
4. **UI Components**: Create reusable components in `Core/Views/`
5. **Feature Implementation**: Build in appropriate `Features/` subdirectory
6. **Integration**: Register navigation and dependencies in `Features/Root/`

### For UI Development
1. **Design System**: Use existing components from `Core/Views/`
2. **Colors & Typography**: Follow patterns in `Core/Infrastructure/Color+Vinylogue.swift`
3. **State Management**: Follow Store-View pattern with `@Observable` stores
4. **Testing**: Include comprehensive SwiftUI previews and screenshot tests

### For Service Development
1. **Protocol Definition**: Define service interface first
2. **Implementation**: Add concrete implementation with proper error handling
3. **Dependency Registration**: Register in `Core/Infrastructure/Dependencies+Vinylogue.swift`
4. **Testing**: Create mock implementation and unit tests
5. **Integration**: Use via `@Dependency` injection in stores

## 🔧 Technical Stack

### Core Technologies
- **SwiftUI**: Declarative UI framework
- **Swift Concurrency**: Async/await for network operations
- **Point-Free Libraries**: Dependencies and Sharing for architecture
- **Nuke**: Advanced image loading and caching

### API Integration
- **Last.fm Web Services API**: Music data and user information
- **JSON Codable**: Type-safe API response handling
- **Structured Error Handling**: Semantic error types with user-friendly messages
- **Multi-Layer Caching**: Memory, disk, and intelligent cache invalidation

### Testing Infrastructure
- **SwiftUI Previews**: Comprehensive preview coverage
- **Screenshot Testing**: Visual regression detection
- **Mock Services**: Realistic test data for all scenarios
- **Dependency Overrides**: Test-specific service implementations

## 📱 Application Flow

### App Initialization
```
App Launch → Migration Check → User Authentication → Main Features
     ↓              ↓                ↓                   ↓
VinylogueApp → RootStore → OnboardingView → WeeklyAlbumsView
```

### User Journey
```
Users List → Weekly Albums → Album Detail
     ↓            ↓             ↓
Select User → Browse Charts → View Details
```

### Data Loading Strategy
```
Cache Check → Background Prefetch → Network Request → UI Update
     ↓              ↓                    ↓              ↓
Instant Load → Smooth Experience → Fresh Data → Reactive UI
```

## 🧪 Quality Assurance

### Testing Strategy
- **Unit Tests**: Core business logic and model validation
- **Integration Tests**: Service integration and data flow testing
- **UI Tests**: Screenshot testing for visual consistency
- **Preview Testing**: Comprehensive SwiftUI preview coverage

### Performance Optimization
- **Progressive Loading**: Essential data first, details in background
- **Concurrent Requests**: Rate-limited parallel API calls
- **Image Optimization**: Smart loading and caching with Nuke
- **Memory Management**: Proper cleanup and bounded caches

### Accessibility
- **Dynamic Type**: Responsive to user font size preferences
- **VoiceOver**: Comprehensive accessibility labels and navigation
- **Color Contrast**: Sufficient contrast ratios throughout
- **Touch Targets**: Appropriate sizes for all interactive elements

## 🔧 Build & Development Tools

### Required Tools
- **Xcode**: Latest version for iOS development
- **SwiftFormat**: Code formatting (run before builds)
- **XcodeGen**: Project file generation (run after file changes)

### Development Commands
```bash
# After adding/removing/renaming files
xcodegen

# Format code before building
swiftformat .

# Build with quiet output
xcodebuild -quiet

# Run unit tests
xcodebuild test -quiet
```

## 📋 Development Guidelines

### Code Style & Patterns
- Follow established Store-View architecture patterns
- Use `@Observable` for reactive state management
- Implement proper error handling with `LocalizedError`
- Include comprehensive SwiftUI previews for all views
- Use dependency injection for all service access

### UI/UX Guidelines
- Match legacy Vinylogue visual design exactly
- NO DARK MODE - design for light mode only
- Use Core UI components for consistency
- Implement proper loading, error, and empty states
- Follow accessibility best practices

### Performance Guidelines
- Use background loading for non-critical data
- Implement proper caching strategies
- Rate-limit concurrent network requests
- Clean up resources when features are dismissed
- Use lazy loading for large data sets

This architecture provides a robust, maintainable foundation for building rich music discovery experiences while ensuring code quality, performance, and exceptional user experience.