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
- **Advanced Scroll Navigation** - 90pt overscroll threshold for year navigation
- **Dynamic Color Theming** - UI adapts to album artwork dominant colors
- **Performance Optimizations** - Background prefetching, concurrent requests with rate limiting
- **Smart Caching** - Prevents duplicate requests with state tracking
- **Enhanced Cancellation** - Actor-based precaching coordinator with memory pressure monitoring
- **Lifecycle Integration** - Automatic cancellation on view disappearance and app backgrounding

## Critical Notes
- WeeklyAlbumsStore handles sophisticated chart period calculations
- AlbumDetailStore provides dynamic color theming from artwork
- Background prefetching for smooth navigation between years with structured cancellation
- All stores integrate with shared navigation path for deep linking
- Memory pressure monitoring automatically cancels background operations
- Comprehensive lifecycle management prevents resource leaks