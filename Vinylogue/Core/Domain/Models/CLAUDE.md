# Data Models Directory Guide

This directory contains the core data models for the Vinylogue application, including Last.FM API integration, user management, and legacy data migration patterns.

## Core Data Models

### 1. User (`User.swift`)
**Purpose**: Represents Last.FM users in the application
- **Key Properties**: `username`, `realName`, `imageURL`, `url`, `playCount`
- **Conformances**: `Codable`, `Identifiable`, `Hashable`, `Sendable`
- **Identity**: Uses lowercased username as `id`
- **Legacy Migration**: Contains `legacyUserDefaultsKey` for migration from old app

### 2. Album Models (`Album.swift`)
Contains two primary album-related models:

#### `AlbumDetail`
**Purpose**: Basic album information without chart context
- **Key Properties**: `name`, `artist`, `url`, `mbid`, `imageURL`, `description`, `totalPlayCount`, `userPlayCount`
- **Conformances**: `Codable`, `Hashable`, `Sendable`

#### `UserChartAlbum`
**Purpose**: Album data within a specific user's weekly chart context
- **Key Properties**: 
  - Chart context: `username`, `weekNumber`, `year`
  - Album identification: `name`, `artist`, `url`, `mbid`
  - Chart data: `playCount`, `rank`
  - Optional detail: `detail` (type `Detail`)
- **Identity**: Composite ID includes user and time context
- **Color Extraction**: Supports dominant color extraction from album artwork with caching

##### `UserChartAlbum.Detail`
**Purpose**: Extended album information loaded separately
- **Color Caching**: Implements sophisticated color extraction caching to avoid repeated processing
- **Properties**: `imageURL`, `description`, `totalPlayCount`, `userPlayCount`
- **Color Methods**: 
  - `dominantColor(from:)`: Extracts and caches color
  - `cachedDominantColor`: Returns cached color without processing
  - `clearColorCache()`: Resets color cache

### 3. Weekly Chart (`WeeklyChart.swift`)
**Purpose**: Container for a user's weekly album chart
- **Key Properties**: `from`, `to` (dates), `albums` (array of `UserChartAlbum`)
- **Computed Properties**: `weekNumber`, `year` derived from dates
- **Conformances**: `Codable`, `Identifiable`, `Hashable`, `Sendable`

## Last.FM API Integration (`LastFMResponses.swift`)

### Response Structure Pattern
All Last.FM API responses follow a nested structure pattern:
```
OuterResponse -> InnerData -> Attributes (@attr) + Content
```

### Key Response Models

#### 1. User Weekly Chart List
- **Entry Point**: `UserWeeklyChartListResponse`
- **Structure**: `weeklychartlist` -> `chart[]` + `@attr`
- **Purpose**: Get list of available weekly chart periods for a user

#### 2. User Weekly Album Chart
- **Entry Point**: `UserWeeklyAlbumChartResponse`
- **Structure**: `weeklyalbumchart` -> `album[]` + `@attr`
- **Key Model**: `LastFMAlbumEntry` with nested `LastFMArtist`
- **Data Conversion**: String playcount/rank converted to Int via computed properties

#### 3. Album Info
- **Entry Point**: `AlbumInfoResponse`
- **Structure**: `album` -> properties + `image[]` + `wiki`
- **Image Handling**: `imageURL` computed property takes last (largest) image
- **Play Counts**: Separate `totalPlayCount` and `userPlayCount` properties

#### 4. User Info
- **Entry Point**: `UserInfoResponse`
- **Structure**: `user` -> properties + `image[]` + `registered`
- **Similar patterns to AlbumInfo for image and playcount handling

#### 5. User Friends
- **Entry Point**: `UserFriendsResponse`
- **Structure**: `friends` -> `user[]` + `@attr` (pagination info)

### Last.FM API Patterns

#### Image Handling
- All image arrays follow same pattern: take `.last?.text` for largest image
- Consistent `imageURL` computed property across models

#### Play Count Conversion
- API returns string values, models provide Int computed properties
- Safe conversion with nil fallback for invalid strings

#### Attribute Encoding
- Last.FM uses `@attr` for metadata, mapped to `attr` properties
- Custom `CodingKeys` handle the `@` prefix

#### Artist Name Encoding
- Artist names often encoded as `#text` in nested objects
- Custom `CodingKeys` handle this pattern

## Legacy Migration (`LegacyModels.swift`)

### Migration Strategy
The app supports migration from a legacy Objective-C version with different data storage patterns.

#### `LegacyUser`
**Purpose**: NSCoding-compatible model for reading old user data
- **Storage**: UserDefaults with NSCoding
- **Key Pattern**: Uses `k` prefixed keys (e.g., `kUserUserName`)
- **Migration**: `toUser()` method converts to new `User` model

#### `LegacyFriend`
**Purpose**: NSCoding-compatible model for reading cached friends
- **Storage**: Previously cached in JSON files
- **Same key pattern**: Uses identical NSCoding keys as LegacyUser

#### `LegacySettings`
**Purpose**: Codable struct for settings migration
- **Key Properties**: `playCountFilter`, `lastOpenedDate`
- **Storage Keys**: Defined in nested `Keys` enum

#### `LegacyData`
**Purpose**: Container for all legacy data during migration
- **Properties**: `user`, `settings`, `friends`, `migrationDate`
- **Usage**: Single container to pass around during migration process

## Shared Keys & Storage (`SharedKeys.swift`)

### Storage Architecture
Uses TCA's `Sharing` library for type-safe shared state management.

#### App Storage Keys
- `currentUser`: String? - Current user's username
- `currentPlayCountFilter`: Int (default: 1) - Filter for minimum play counts
- `migrationCompleted`: Bool (default: false) - Migration completion flag

#### File Storage Keys
- `curatedFriends`: [User] (default: []) - Curated friends list stored in JSON

#### In-Memory Keys
- `navigationPath`: [AppModel.Path] (default: []) - Navigation state for TCA

#### File URLs
- `curatedFriendsURL`: Points to `documentsDirectory/curatedFriends.json`

## Color Extraction Integration

### ColorExtraction Utility
Referenced by `UserChartAlbum.Detail` for album artwork color analysis:
- **Primary Method**: `ColorExtraction.dominantColor(from: UIImage) -> Color?`
- **Caching Strategy**: Colors cached per Detail instance to avoid reprocessing
- **Performance**: Extraction only occurs when explicitly requested with image

## Key Patterns & Best Practices

### 1. Model Conformances
All models should conform to:
- `Codable` for JSON serialization
- `Sendable` for Swift concurrency safety
- `Identifiable` for SwiftUI list performance
- `Hashable` for efficient comparisons

### 2. API Response Processing
- Use computed properties for type conversion (String -> Int)
- Handle nil values gracefully with fallbacks
- Extract common patterns (like imageURL) into computed properties

### 3. Legacy Migration
- Never remove legacy model support until migration is complete
- Use conversion methods (`toUser()`) rather than direct property mapping
- Maintain backward compatibility with old storage keys

### 4. Performance Considerations
- Color extraction should be lazy and cached
- Large data sets (like friends lists) should use file storage
- Use shared keys pattern for consistent state management

### 5. Last.FM API Integration
- Always handle API inconsistencies (string vs number types)
- Use nested response structures to match API exactly
- Implement custom CodingKeys for API naming conventions
- Extract useful computed properties for common UI needs

## Model Relationships

```
User ←→ UserChartAlbum (via username)
UserChartAlbum → UserChartAlbum.Detail (optional detail loading)
WeeklyChart → [UserChartAlbum] (contains array)
LastFMResponses → UserChartAlbum (conversion via parsing)
LegacyModels → User (migration via toUser())
```

## Usage Examples

### Creating a UserChartAlbum
```swift
let album = UserChartAlbum(
    username: "lastfmuser",
    weekNumber: 42,
    year: 2023,
    name: "The Dark Side of the Moon",
    artist: "Pink Floyd",
    playCount: 15,
    rank: 1
)
```

### Loading Detail Information
```swift
var album = existingAlbum
// Load detail from AlbumInfoResponse
album.detail = UserChartAlbum.Detail(
    imageURL: response.album.imageURL,
    description: response.album.description,
    totalPlayCount: response.album.totalPlayCount,
    userPlayCount: response.album.userPlayCount
)
```

### Color Extraction
```swift
var album = albumWithDetail
if let image = loadedUIImage {
    let color = album.dominantColor(from: image)
    // Color is now cached for future access
    let cachedColor = album.cachedDominantColor
}
```