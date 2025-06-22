# Core/Domain Directory

## Overview
Core business logic and data models independent of UI concerns.

## Subdirectories
- **Models/** - Data structures, API responses, legacy migration
- **Services/** - Business logic services for API, caching, migration

## Key Patterns
- **Models** - Codable + Sendable + Identifiable + Hashable for SwiftUI
- **Services** - Protocol-based with dependency injection and async/await
- **Legacy Migration** - One-time NSCoding → Codable conversion
- **Shared State** - TCA Sharing library with typed keys

## Data Flow
Last.fm API → LastFMResponses → Domain Models → UI
Network → Cache Check → API Call → Cache Store → Return