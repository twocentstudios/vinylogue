# Infrastructure Directory

## Files
- `CacheKeyBuilder.swift` - Consistent cache key generation (prefers MBID over names)
- `Calendar+WeekCalculations.swift` - Weekly chart date calculations and year navigation
- `Color+Vinylogue.swift` - Legacy color palette (light mode only) and typography
- `ColorExtraction.swift` - Advanced color extraction from album artwork (Objective-C port)
- `Dependencies+Vinylogue.swift` - Dependency injection setup with realistic mocks
- `Environment+Keys.swift` - SwiftUI Environment keys (legacy compatibility)
- `EquatableError.swift` - Error wrapper for SwiftUI state management
- `ImagePipeline+Vinylogue.swift` - Nuke image pipeline with temporary disk caching
- `Secrets.swift` - API key management (currently hardcoded)
- `TestingUtilities.swift` - Testing environment detection and test data utilities
- `NavigationTintPreferenceKey.swift` - Custom PreferenceKey for NavigationStack tint control

## Critical Notes
- **NO DARK MODE** - Entire color system designed for light mode only
- **Color Extraction** - Direct Objective-C port with two-pass pixel analysis
- **Cache Keys** - Hierarchical approach prioritizing MBID over artist/album names
- **Week Calculations** - Essential for weekly chart features and year comparisons
- **Testing Support** - Environment detection, mock data, realistic test scenarios