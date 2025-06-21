# Features/Main Directory

## Core App Features
- `UsersListStore/View.swift` - User selection and friends management
- `WeeklyAlbumsStore/View.swift` - Weekly charts with year navigation
- `AlbumDetailStore/View.swift` - Rich album details with dynamic color theming
- `AlbumRowView.swift` - Reusable list component with consistent styling

## Architecture Pattern
Consistent **Store + View** pattern:
- `@Observable` stores for state management and business logic
- `@Shared` for global state (user, friends, navigation)
- Multi-layered caching (memory + disk) with background prefetching
- Smart cache invalidation based on user/filter changes

## Key Features
- **Advanced Scroll Navigation**: 90pt overscroll threshold for year navigation
- **Dynamic Color Theming**: UI adapts to album artwork dominant colors
- **Performance Optimizations**: Background prefetching, concurrent requests with rate limiting
- **Smart Caching**: Prevents duplicate requests with state tracking

## Critical Notes
- WeeklyAlbumsStore handles sophisticated chart period calculations
- AlbumDetailStore provides dynamic color theming from artwork
- Background prefetching for smooth navigation between years
- All stores integrate with shared navigation path for deep linking

**Navigation**:
- Creates `WeeklyAlbumsStore` for selected user
- Navigates via shared navigation path
- Proper store dependency injection

**UI Patterns**:
- Section-based layout with custom headers
- Differentiated styling for current user vs friends
- Button styles with press states and haptic feedback
- Toolbar with settings and edit actions

### Weekly Albums (`WeeklyAlbumsStore` + `WeeklyAlbumsView`)

**Purpose**: Core feature displaying weekly album charts with year navigation

**Data Loading Strategy**:
- Loads available chart periods on initialization
- Calculates target dates based on year offsets
- Implements aggressive caching with cache keys
- Background prefetching for adjacent years
- Concurrent album detail loading with rate limiting

**State Management**:
```swift
enum WeeklyAlbumsLoadingState: Equatable {
    case initialized
    case loading
    case loaded([UserChartAlbum])
    case failed(LastFMError)
}
```

**Performance Optimizations**:
- Image prefetching using Nuke's `ImagePrefetcher`
- Concurrent album detail requests (max 5 concurrent)
- Smart data reloading based on user/filter/year changes
- Background precaching for previous year data

**Navigation Patterns**:
- Year offset-based navigation (1 = last year, 2 = two years ago)
- Overscroll gesture detection for year navigation
- Visual feedback during navigation transitions
- Floating navigation buttons with progress indicators

**UI Patterns**:
- Overscroll handlers with threshold detection (90pt)
- Animated year navigation buttons with scale effects
- Scroll position management and smooth transitions
- Loading states in toolbar and content areas

**Scroll Navigation Implementation**:
```swift
// Overscroll threshold detection
private static let overscrollThreshold: CGFloat = 90

// Visual progress indicators
let newTopProgress = max(0.0, topOverscroll / Self.overscrollThreshold)
let newBottomProgress = max(0.0, bottomOverscroll / Self.overscrollThreshold)
```

### Album Detail (`AlbumDetailStore` + `AlbumDetailView`)

**Purpose**: Rich album detail view with dynamic color theming

**Color Theming System**:
- Extracts representative colors from album artwork
- Animates color transitions with timing control
- Provides accessible text colors based on background
- Maintains fallback colors for loading/error states

**Dynamic UI Theming**:
```swift
var animatedBackgroundColor: Color {
    if shouldAnimateColors, let representativeColors {
        return representativeColors.primary
    }
    return Color.vinylogueWhiteSubtle
}
```

**Layout Structure**:
- Scrollable content with background artwork blur
- Prominent album artwork with shadow effects
- Dual play count display (period vs all-time)
- Rich text description with proper typography
- Loading states with animated indicators

**Image Loading Integration**:
- Uses `ReusableAlbumArtworkView.flexible()` for artwork
- Triggers color extraction on image load completion
- Handles loading, error, and placeholder states
- Maintains aspect ratio and proper sizing

### Album Row (`AlbumRowView`)

**Purpose**: Reusable component for displaying albums in lists

**Design Patterns**:
- Fixed height rows with consistent spacing
- Album artwork, artist/album text, and play count layout
- Subtle borders and shadows for depth
- Responsive text sizing and truncation

**Integration Points**:
- Uses `ReusableAlbumArtworkView.fixedSize()` for consistency
- Implements custom button style (`AlbumRowButtonStyle`)
- Proper content shape for tap targets
- Accessible text hierarchy

## Supporting Infrastructure

### ReusableAlbumArtworkView
**Purpose**: Unified album artwork component with multiple display modes

**Key Features**:
- Fixed size mode for lists (80pt default)
- Flexible aspect ratio mode for detail views
- Placeholder view with vinyl record icon design
- Image loading callbacks for color extraction
- Shadow and corner radius customization
- Test-friendly with pixelation processor

**Usage Patterns**:
```swift
// Fixed size for rows
ReusableAlbumArtworkView.fixedSize(imageURL: album.detail?.imageURL, size: 80)

// Flexible for detail views
ReusableAlbumArtworkView.flexible(
    imageURL: store.album.detail?.imageURL,
    cornerRadius: 6,
    showShadow: true,
    onImageLoaded: { uiImage in
        store.extractRepresentativeColors(from: uiImage)
    }
)
```

### ColorExtraction
**Purpose**: Advanced color analysis for dynamic UI theming

**Algorithm**: Direct port from legacy Objective-C implementation
- Excludes very bright/dark pixels (brightness 0.05-0.95)
- Separates colors into primary/secondary bins using 0.35 threshold
- Calculates appropriate text colors based on background brightness
- Provides multiple color variants (primary, secondary, average, text, shadow)

**Integration**:
- Called from `AlbumDetailStore.extractRepresentativeColors()`
- Results stored in `RepresentativeColors` struct
- Used for dynamic background, text, and shadow colors

### AnimatedLoadingIndicator
**Purpose**: Branded loading animation using vinyl record frames

**Implementation**:
- 12-frame animation sequence (loading01-loading12)
- 0.5 second total duration with smooth transitions
- Configurable size for different contexts
- Timeline-based animation for consistent performance

## Data Flow Patterns

### Cache Strategy
1. **Cache Keys**: Structured keys using `CacheKeyBuilder`
   - Weekly charts: username + date range
   - Chart lists: username only
2. **Cache Hierarchy**: Memory → Disk → Network
3. **Prefetching**: Background loading for adjacent data
4. **Invalidation**: Based on user/filter changes

### Loading States
1. **Initialized**: Initial state before any data loading
2. **Loading**: Active network request in progress
3. **Loaded**: Data successfully loaded and cached
4. **Failed**: Error state with specific `LastFMError` types

### Navigation Flow
```
UsersListView → WeeklyAlbumsView → AlbumDetailView
     ↓               ↓                    ↓
UsersListStore → WeeklyAlbumsStore → AlbumDetailStore
```

## Best Practices

### Store Implementation
- Always implement `Hashable` for navigation compatibility
- Use `@MainActor` for UI-related stores
- Implement proper cleanup in `clear()` methods
- Track loading state to prevent duplicate requests

### View Implementation
- Use `@Bindable` for store references
- Implement proper loading and error states
- Use `task(id:)` for reactive data loading
- Implement accessibility features and proper content shapes

### Performance Considerations
- Implement background prefetching for smooth UX
- Use concurrent task groups with rate limiting
- Cache aggressively but invalidate appropriately
- Use `LazyVStack`/`LazyHStack` for large lists

### Error Handling
- Gracefully handle network failures
- Provide meaningful error messages to users
- Implement retry mechanisms where appropriate
- Maintain partial functionality during errors

## Integration Guidelines

### Adding New Features
1. Follow Store-View pattern established by existing features
2. Implement proper state management with loading states
3. Use shared navigation path for consistent routing
4. Integrate with existing caching and prefetching systems

### Modifying Existing Features
1. Maintain backward compatibility with navigation
2. Preserve existing state management patterns
3. Update cache invalidation logic if data structures change
4. Test color theming integration for album-related features

### Testing Considerations
- Use preview data that matches production data structures
- Test loading, loaded, and error states
- Verify navigation flows between features
- Test color extraction with various image types
- Verify accessibility features work correctly

This architecture provides a robust foundation for rich, performant music discovery features while maintaining consistency and extensibility for future enhancements.