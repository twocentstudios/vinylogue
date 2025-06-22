# Data Models Directory

## Files
- `User.swift` - Last.FM user representation
- `Album.swift` - `UserChartAlbum` (main model) and `AlbumDetail`
- `WeeklyChart.swift` - Container for weekly album charts
- `LastFMResponses.swift` - All Last.FM API response models
- `LegacyModels.swift` - NSCoding models for migration from Objective-C app
- `SharedKeys.swift` - Type-safe shared state keys using TCA Sharing

## Key Patterns
- **Core Model** - `UserChartAlbum` links user, time, album with optional `Detail`
- **API Structure** - `OuterResponse -> InnerData -> @attr + Content`
- **Color Extraction** - Cached in `UserChartAlbum.Detail` per instance
- **Legacy Migration** - `LegacyUser/Friend/Settings` convert via `toUser()`
- **Shared State** - TCA Sharing with AppStorage/FileStorage

## Critical Notes
- API returns strings for numbers - use computed properties
- Image URLs: take `.last?.text` for largest size
- Color extraction cached to avoid reprocessing