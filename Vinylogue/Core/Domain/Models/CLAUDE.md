# Data Models Directory

## Files
- `User.swift` - Last.FM user representation
- `Album.swift` - `UserChartAlbum` (main model) and `AlbumDetail`
- `WeeklyChart.swift` - Container for weekly album charts
- `LastFMResponses.swift` - All Last.FM API response models
- `LegacyModels.swift` - NSCoding models for migration from Objective-C app
- `SharedKeys.swift` - Type-safe shared state keys using TCA Sharing

## Key Patterns
- **Core Model**: `UserChartAlbum` - links user, time period, and album with optional `Detail`
- **Last.FM API**: Nested response structure `OuterResponse -> InnerData -> @attr + Content`
- **Color Extraction**: `UserChartAlbum.Detail` has cached color extraction for album artwork
- **Legacy Migration**: `LegacyUser/Friend/Settings` convert to modern models via `toUser()`
- **Shared State**: Uses TCA Sharing with AppStorage/FileStorage for global state

## Critical Notes
- Last.FM API returns strings for numbers - use computed properties for conversion
- Image URLs: take `.last?.text` from image arrays for largest size
- Color extraction is cached per Detail instance to avoid reprocessing
- Legacy migration handles NSCoding -> Codable conversion