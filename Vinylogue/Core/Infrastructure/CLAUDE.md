# Infrastructure Directory

## Files
- `CacheKeyBuilder.swift` - Consistent cache key generation (prefers MBID over names)
- `Calendar+WeekCalculations.swift` - Weekly chart date calculations and year navigation
- `Color+Vinylogue.swift` - Legacy color palette (light mode only) and typography
- `ColorExtraction.swift` - Advanced color extraction from album artwork (ported from Objective-C)
- `Dependencies+Vinylogue.swift` - Dependency injection setup with realistic mocks
- `Environment+Keys.swift` - SwiftUI Environment keys (legacy compatibility)
- `EquatableError.swift` - Error wrapper for SwiftUI state management
- `ImagePipeline+Vinylogue.swift` - Nuke image pipeline with temporary disk caching
- `Secrets.swift` - API key management (currently hardcoded)
- `TestingUtilities.swift` - Testing environment detection and test data utilities

## Critical Notes
- **NO DARK MODE**: Entire color system designed for light mode only, matching legacy app
- **Color Extraction**: Direct Objective-C port with two-pass pixel analysis for accuracy
- **Cache Keys**: Hierarchical approach prioritizing MBID over artist/album names
- **Week Calculations**: Essential for weekly chart features and year-over-year comparisons

---

## Calendar and Date Utilities

**File:** `Calendar+WeekCalculations.swift`

Extends Calendar and Date with week-based calculations, essential for weekly chart features.

### Calendar Extensions

```swift
// Get same week from previous years
calendar.sameWeekInPreviousYear(date, yearsAgo: 1)

// Get week components
let (weekOfYear, yearForWeekOfYear) = calendar.weekComponents(from: date)

// Check if dates are in same week
calendar.isDate(date1, inSameWeekAs: date2)
```

### Date Extensions

```swift
// Shift date by years while preserving week
let lastYear = currentDate.shiftedByYears(1)

// Get week components directly
let weekInfo = date.weekComponents
```

### Usage Notes
- Uses `yearForWeekOfYear` for proper week calculations across year boundaries
- Essential for weekly chart comparisons and "same week last year" features
- Handles edge cases where week calculations might fail

---

## Color System and Processing

**File:** `Color+Vinylogue.swift`

Implements the legacy Vinylogue color palette and typography system with **NO DARK MODE SUPPORT**.

### Color Palette

```swift
// Primary colors (legacy design - always light mode)
Color.primaryText        // Dark blue text
Color.primaryBackground  // Subtle white background
Color.accent            // System accent color
Color.destructive       // Red for destructive actions

// Legacy Vinylogue colors (from TCSVinylogueDesign.h)
Color.vinylogueWhiteSubtle  // RGB(240, 240, 240)
Color.vinylogueBlueDark     // RGB(15, 24, 46)
Color.vinylogueBluePeri     // RGB(220, 220, 220)
Color.vinylogueGray         // Alias for BluePeri
```

### Typography System

```swift
// Font system using AvenirNext family
Font.f(.ultralight, .title)        // Style-based sizing
Font.f(.regular, 16)               // Fixed point sizing

// Available font weights
VinylogueFont.ultralight, .regular, .medium, .demiBold, .bold, .heavy
```

### Critical Notes
- **NO DARK MODE SUPPORT** - All colors are designed for light mode only
- Colors match the legacy Objective-C application exactly
- Use `Color.primaryText` and `Color.primaryBackground` for consistency
- Font system uses AvenirNext family exclusively

---

## Color Extraction from Images

**File:** `ColorExtraction.swift`

Advanced color extraction system ported directly from the legacy Objective-C implementation.

### Core Functionality

```swift
// Extract comprehensive color palette
if let colors = ColorExtraction.extractRepresentativeColors(from: uiImage) {
    let primaryColor = colors.primary      // Main dominant color
    let secondaryColor = colors.secondary  // Secondary dominant color
    let averageColor = colors.average      // Overall average color
    let textColor = colors.text           // Optimal text color
    let shadowColor = colors.textShadow   // Text shadow color
}

// Simple dominant color extraction
let dominantColor = ColorExtraction.dominantColor(from: uiImage)

// UIImage extension
let dominantColor = uiImage.dominantColor
```

### UI Enhancement Functions

```swift
// Enhance colors for better UI contrast
let enhancedColor = ColorExtraction.enhanceForUI(originalColor)

// Create background gradients
let gradient = ColorExtraction.createBackgroundGradient(from: dominantColor)
```

### Algorithm Details
- **Two-pass analysis**: First calculates average, second separates primary/secondary
- **Brightness filtering**: Excludes very dark (< 5%) and very bright (> 95%) pixels
- **Color binning**: Groups similar colors together using 35% tolerance
- **Text color calculation**: Automatically determines optimal text color based on background
- **Perfect legacy port**: Algorithm matches vinylogue-legacy exactly

### Performance Notes
- Processes images pixel-by-pixel for accuracy
- Uses Core Graphics bitmap context for efficient processing
- Should be called on background queue for large images

---

## Dependency Injection

**File:** `Dependencies+Vinylogue.swift`

Configures dependency injection using the Dependencies library for testable, modular architecture.

### Available Dependencies

```swift
@Dependency(\.lastFMClient) var lastFMClient
@Dependency(\.cacheManager) var cacheManager  
@Dependency(\.imagePipeline) var imagePipeline
```

### Mock Implementations

The file includes comprehensive mock implementations:

#### MockLastFMClient Features
- **Realistic mock data** for all LastFM endpoints
- **Dynamic chart periods** (2 years of weekly data)
- **Multiple mock albums** for better preview experience
- **Proper timestamp generation** for current week calculations

#### Test Overrides
```swift
// In tests, override dependencies
withDependencies {
    $0.lastFMClient = TestLastFMClient()
} operation: {
    // Test code here
}
```

### Environment Values (Legacy Support)
- Also provides SwiftUI Environment value support
- Use `@Dependency` for new code, `@Environment` for compatibility

---

## Environment Configuration

**File:** `Environment+Keys.swift`

Provides SwiftUI Environment keys for dependency injection (legacy approach).

### Usage
```swift
// In SwiftUI views (legacy approach - prefer @Dependency)
@Environment(\.lastFMClient) private var lastFMClient
@Environment(\.imagePipeline) private var imagePipeline
```

**Note:** This is maintained for compatibility. New code should use `@Dependency` from `Dependencies+Vinylogue.swift`.

---

## Error Handling

**File:** `EquatableError.swift`

Provides a wrapper to make any Error type Equatable, essential for SwiftUI state management and testing.

### Usage

```swift
// Make any error equatable
let equatableError = someError.toEquatableError()

// Use in SwiftUI state
@State private var error: EquatableError?

// In view updates, SwiftUI can now properly compare errors
if let error = error {
    Text("Error: \(error.description)")
}

// Test error equality
XCTAssertEqual(error1.toEquatableError(), error2.toEquatableError())

// Extract original error type
if let lastFMError = equatableError.asError(type: LastFMError.self) {
    // Handle specific error type
}
```

### Key Features
- **Generic wrapper** for any Error type
- **String-based comparison** for non-Equatable errors
- **Type-safe comparison** for Equatable errors
- **Original error preservation** with extraction capabilities
- **Sendable conformance** for concurrency safety

---

## Image Pipeline

**File:** `ImagePipeline+Vinylogue.swift`

Configures Nuke ImagePipeline with temporary disk caching for album artwork and user images.

### Configuration

```swift
// Create pipeline with temporary disk cache
let pipeline = ImagePipeline.withTemporaryDiskCache()
```

### Features
- **Temporary directory caching** (`/tmp/VinylogueImages`)
- **Automatic directory creation** if needed
- **Memory + disk caching** via Nuke DataCache
- **Integrated with dependency injection** system

### Usage Notes
- Used automatically via dependency injection
- Cache survives app lifecycle but not device restarts
- Handles cache directory creation failures gracefully

---

## Secrets Management

**File:** `Secrets.swift`

**⚠️ IMPORTANT:** Contains hardcoded API keys - should be externalized for production.

### Current Implementation
```swift
Secrets.apiKey  // Returns Last.fm API key
```

### Security Notes
- **API key is hardcoded** in source code
- **Should be moved** to environment variables or secure configuration
- **Not suitable for production** without proper secret management
- Consider using build-time configuration or secure keychain storage

---

## Testing Utilities

**File:** `TestingUtilities.swift`

Provides utilities for detecting testing environments and managing test data.

### Environment Detection

```swift
// Check if running in test environment
if TestingUtilities.isTesting {
    // Test-specific behavior
}

// Check if running screenshot tests
if TestingUtilities.isScreenshotTesting {
    // Screenshot test specific setup
}

// Global convenience properties
if isTesting { /* ... */ }
if isScreenshotTesting { /* ... */ }
```

### Test Data Management

```swift
// Get structured test data
let testUser = TestingUtilities.getTestData(
    for: "TEST_USER_DATA", 
    type: UserInfo.self
)

// Get string test data
let testUsername = TestingUtilities.getTestString(for: "TEST_USERNAME")
```

### Usage Patterns
- **Launch arguments detection** for screenshot testing (`--screenshot-testing`)
- **Environment variable parsing** for test data injection
- **JSON decoding** of complex test data structures
- **Global convenience properties** for easy access

---

## Best Practices Summary

### Cache Keys
- Always use `CacheKeyBuilder` instead of manual key construction
- Prefer MBID over artist/album name when available
- Include username for user-specific data

### Colors & Design
- Use `Color.primaryText` and `Color.primaryBackground` for consistency
- NO DARK MODE - design is light mode only
- Reference legacy colors for exact visual matching
- Use font system with `Font.f()` helper

### Color Extraction
- Call on background queue for large images
- Use `extractRepresentativeColors()` for comprehensive palette
- Use `dominantColor` for simple use cases
- Apply `enhanceForUI()` for better contrast

### Dependencies
- Use `@Dependency` for new code
- Override in tests with `withDependencies`
- Mock implementations provide realistic data

### Error Handling
- Convert errors to `EquatableError` for SwiftUI state
- Use `asError(type:)` to extract original error types
- Essential for proper SwiftUI view updates

### Testing
- Check `isTesting` for test-specific behavior
- Use launch arguments for screenshot testing
- Inject test data via environment variables

---

## Integration with Other Systems

### Caching Integration
```swift
// Use with CacheManager
let cacheKey = CacheKeyBuilder.albumInfo(artist: "Artist", album: "Album")
let cachedData = cacheManager.get(key: cacheKey, type: AlbumInfo.self)
```

### Color Integration
```swift
// Extract colors and apply to UI
if let colors = ColorExtraction.extractRepresentativeColors(from: albumImage) {
    let gradient = ColorExtraction.createBackgroundGradient(from: colors.primary)
    // Apply gradient to background
}
```

### Testing Integration
```swift
// In test setup
withDependencies {
    $0.lastFMClient = TestLastFMClient()
    $0.cacheManager = CacheManager() // Uses temporary directory
} operation: {
    // Test your views/logic here
}
```