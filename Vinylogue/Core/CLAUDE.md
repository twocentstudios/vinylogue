# Core Directory

## Overview
Foundation layer providing infrastructure, services, and reusable components.

## Subdirectories
- **Domain/** - Business logic, data models, services
- **Infrastructure/** - Utilities, extensions, configuration
- **Views/** - Reusable UI components and design system

## Critical Constraints
- **NO DARK MODE** - Light mode only, matches legacy design
- **Legacy Colors** - Use predefined colors from `TCSVinylogueDesign.h`
- **Typography** - AvenirNext family via `.f()` helper

## Architecture
- **SwiftUI + @Observable** - Modern state with Point-Free Sharing
- **Protocol Services** - Dependency injection for testability
- **Type Safety** - Codable + Sendable + Identifiable throughout
- **Multi-Layer Caching** - Memory → Disk → Network with smart invalidation