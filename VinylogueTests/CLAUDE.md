# VinylogueTests Directory Guide

This directory contains the unit test suite for the Vinylogue iOS application. This guide provides comprehensive information about the testing architecture, patterns, utilities, and best practices for writing and maintaining tests in this codebase.

## Testing Architecture & Frameworks

### Core Testing Framework
- **XCTest**: Primary testing framework
- **@testable import Vinylogue**: Provides access to internal app components
- **Swift 6.0** with strict concurrency enabled
- **iOS 18.0** minimum deployment target

### Key Testing Dependencies
- **Dependencies**: Point-Free's dependency injection framework for mocking dependencies
- **Sharing**: Point-Free's shared state management for testing settings and persistence
- **Foundation**: For core data types and async testing

### Concurrency & MainActor
- Tests that interact with UI components or @MainActor isolated code use `@MainActor` annotation
- Async/await patterns are used extensively for testing asynchronous operations
- MainActor isolation is properly handled in test setup/teardown methods

## Test Organization & Structure

### Test File Structure
```
VinylogueTests/
├── CacheManagerTests.swift          # Cache and persistence testing
├── ColorExtractionTests.swift       # Image color analysis testing
├── FriendsImporterTests.swift       # Friend data import logic
├── LastFMClientTests.swift          # API client and networking
├── LegacyMigratorTests.swift        # Legacy data migration
├── WeeklyAlbumsStoreTests.swift     # Core business logic store
└── TestUtilities/
    ├── AssertionHelpers.swift       # Custom assertion helpers
    ├── TestDataFactory.swift       # Test data builders
    └── TestLastFMClient.swift       # Mock API client
```

### Test Classes
- All test classes inherit from `XCTestCase`
- Follow the naming convention: `{ComponentName}Tests`
- Use `final` keyword for test classes
- Implement proper `setUp()` and `tearDown()` lifecycle methods

### Test Method Naming
- Use descriptive names that explain the test scenario
- Format: `test{ActionOrCondition}{ExpectedOutcome}`
- Examples:
  - `testStoreAndRetrieveString()`
  - `testImportFriendsNetworkError()`
  - `testDominantColorFromSolidRedImage()`

## Testing Patterns & Strategies

### 1. Dependency Injection Testing
Uses Point-Free's Dependencies framework for clean dependency management:

```swift
store = withDependencies {
    $0.lastFMClient = mockLastFMClient
    $0.date = .constant(testDate)
    $0.calendar = testCalendar
} operation: {
    WeeklyAlbumsStore(user: testUser)
}
```

### 2. Given-When-Then Structure
Tests follow the AAA (Arrange-Act-Assert) pattern:

```swift
func testStoreAndRetrieveString() async throws {
    // Given
    let testString = "Hello, Vinylogue!"
    let key = "test_key"
    
    // When
    try await cacheManager.store(testString, key: key)
    let retrieved: String? = try await cacheManager.retrieve(String.self, key: key)
    
    // Then
    XCTAssertEqual(retrieved, testString)
    
    // Cleanup
    try await cacheManager.remove(key: key)
}
```

### 3. Error Testing Patterns
Comprehensive error handling testing with custom assertion helpers:

```swift
func testImportFriendsNetworkError() async {
    // Given: Mock API error
    mockLastFMClient.mockError = LastFMError.networkUnavailable
    
    // When: Importing friends
    await friendsImporter.importFriends(for: "testuser")
    
    // Then: Error is handled correctly
    guard case let .failed(error) = friendsImporter.friendsState else {
        XCTFail("Expected friends import to fail")
        return
    }
    
    if let lastFMError = error.asError(type: LastFMError.self),
       case LastFMError.networkUnavailable = lastFMError {
        // Expected error type
    } else {
        XCTFail("Expected network unavailable error")
    }
}
```

### 4. Performance Testing
Uses XCTest's `measure` block for performance testing:

```swift
func testColorExtractionPerformance() {
    let testImage = createTestImage(color: .magenta, size: CGSize(width: 200, height: 200))
    
    measure {
        _ = ColorExtraction.dominantColor(from: testImage)
    }
}
```

### 5. Image Testing Patterns
Custom image creation for testing visual components:

```swift
private func createTestImage(color: UIColor, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        color.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
}
```

## Test Utilities & Helpers

### 1. TestDataFactory
Central factory for creating test data objects:

```swift
// User creation
let user = TestDataFactory.createUser(
    username: "testuser",
    realName: "Test User",
    playCount: 100
)

// Album creation
let album = TestDataFactory.createUserChartAlbum(
    name: "Test Album",
    artist: "Test Artist",
    playCount: 50,
    rank: 1,
    withDetail: true
)

// Batch creation
let users = TestDataFactory.createUsers(count: 5, usernamePrefix: "user")
let albums = TestDataFactory.createUserChartAlbums(count: 10, username: "testuser")
```

**Key Features:**
- Provides sensible defaults for all parameters
- Supports batch creation with customizable prefixes
- Handles complex nested objects (like album details)
- Includes legacy model creation for migration testing
- Date utilities for consistent date handling

### 2. AssertionHelpers
Custom assertion methods for domain-specific objects:

```swift
// User assertions
assertUsersEqual(actualUser, expectedUser)
assertUser(user, hasUsername: "testuser", realName: "Test User", playCount: 100)

// Album assertions
assertUserChartAlbumsEqual(actualAlbum, expectedAlbum)
assertUserChartAlbum(album, hasUsername: "testuser", name: "Test Album", artist: "Test Artist")

// Collection assertions
assertUsers(users, containUsernames: ["user1", "user2", "user3"])
assertAlbums(albums, containAlbumNames: ["Album 1", "Album 2"])
assertUserChartAlbumsSortedByRank(albums)

// Error assertions
await assertThrowsLastFMError(
    try await client.fetchUser("nonexistent"),
    expectedError: .userNotFound
)
```

**Benefits:**
- Provides meaningful error messages with context
- Handles optional values gracefully
- Includes file and line information for debugging
- Supports async error testing
- Domain-specific comparisons for complex objects

### 3. TestLastFMClient
Comprehensive mock implementation of the LastFM API client:

```swift
final class TestLastFMClient: LastFMClientProtocol, @unchecked Sendable {
    // Thread-safe mock response system
    func setMockResponse(_ response: some Codable, forEndpoint endpoint: LastFMEndpoint)
    func setGenericMockResponse(_ response: some Codable)
    
    // Error simulation
    var mockError: Error?
    var shouldReturnError: Bool
    
    // Structured mock data
    var mockCharts: [ChartPeriod]
    var mockAlbums: [LastFMAlbumEntry]
    
    // Clean reset for test isolation
    func reset()
}
```

**Key Features:**
- Thread-safe implementation with NSLock
- Supports endpoint-specific and generic responses
- Error simulation capabilities
- Structured mock data for common scenarios
- Clean reset functionality for test isolation

## Mock Implementation Patterns

### 1. Dependency Injection Mocks
```swift
mockLastFMClient = TestLastFMClient()
store = withDependencies {
    $0.lastFMClient = mockLastFMClient
} operation: {
    WeeklyAlbumsStore(user: testUser)
}
```

### 2. Response Setup Patterns
```swift
// Endpoint-specific response
let mockResponse = UserWeeklyChartListResponse(...)
mockClient.setMockResponse(mockResponse, forEndpoint: .userWeeklyChartList(username: "user"))

// Generic response for flexible testing
mockClient.setGenericMockResponse(mockResponse)
```

### 3. Error Simulation
```swift
// Specific error
mockClient.mockError = LastFMError.networkUnavailable

// Generic error condition
mockClient.shouldReturnError = true
```

## Test Data Management

### Test Isolation
- Each test creates its own mock instances
- Tests clean up after themselves (cache cleanup, temp files)
- Mock clients are reset between tests
- Temporary UserDefaults suites for settings testing

### Temporary Resources
```swift
// Temporary UserDefaults for settings testing
let suiteName = "test-\(UUID().uuidString)"
tempUserDefaults = UserDefaults(suiteName: suiteName)!

// Temporary directories for file operations
tempDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("LegacyMigratorTests-\(UUID().uuidString)")
```

### Test Data Factories
- Use `TestDataFactory` for consistent test data
- Provide meaningful defaults
- Support customization for specific test scenarios
- Handle complex object hierarchies

## Testing Strategies by Component Type

### 1. Cache & Persistence Testing
- Test storage and retrieval of different data types
- Verify error handling for non-existent keys
- Test array storage and complex object serialization
- Include cleanup verification

### 2. Network Client Testing
- Mock API responses for various scenarios
- Test URL building and parameter encoding
- Verify response parsing and error handling
- Test error mapping from API error codes

### 3. Business Logic Testing
- Test state transitions and business rules
- Verify data transformations
- Test edge cases and error conditions
- Mock dependencies for isolated testing

### 4. Migration Testing
- Test data migration from legacy formats
- Verify cleanup of old data
- Test partial migration scenarios
- Use temporary storage for isolation

### 5. Image Processing Testing
- Create test images programmatically
- Test edge cases (small images, large images)
- Verify algorithm behavior without pixel-perfect comparison
- Include performance testing for expensive operations

## Best Practices

### 1. Test Structure
- Use descriptive test method names
- Follow Given-When-Then pattern
- Group related tests with MARK comments
- Keep tests focused and single-purpose

### 2. Async Testing
- Use `async/await` for asynchronous operations
- Handle MainActor isolation properly
- Test timeout scenarios appropriately
- Verify concurrent operations work correctly

### 3. Error Testing
- Test both success and failure paths
- Use custom assertion helpers for domain errors
- Verify error messages and types
- Test error recovery scenarios

### 4. Mock Usage
- Use dependency injection for clean mocking
- Reset mocks between tests
- Verify mock interactions when needed
- Keep mocks simple and focused

### 5. Test Data
- Use factories for consistent test data
- Provide meaningful defaults
- Make test data representative of real usage
- Clean up test data and resources

### 6. Assertions
- Use domain-specific assertion helpers
- Provide meaningful failure messages
- Test both positive and negative cases
- Verify all important properties

## Writing New Tests

### 1. Choose the Right Test Type
- **Unit tests**: Business logic, data transformations, utilities
- **Integration tests**: Component interactions, API client behavior
- **Performance tests**: Expensive operations, algorithms

### 2. Structure Your Test Class
```swift
@MainActor  // If needed for UI components
final class NewComponentTests: XCTestCase {
    nonisolated var component: NewComponent!
    nonisolated var mockDependency: MockDependency!
    
    override func setUpWithError() throws {
        // Setup will be done in test methods for MainActor components
    }
    
    override func tearDownWithError() throws {
        component = nil
        mockDependency = nil
    }
    
    // Test methods...
}
```

### 3. Use the Test Utilities
- Leverage `TestDataFactory` for creating test data
- Use `AssertionHelpers` for domain-specific assertions
- Use `TestLastFMClient` for API mocking

### 4. Follow the Patterns
- Use dependency injection for mocking
- Follow Given-When-Then structure
- Clean up resources in tests
- Use meaningful test names

### 5. Test Coverage Areas
- Happy path scenarios
- Error conditions and edge cases
- Boundary conditions
- State transitions
- Data transformations
- Performance characteristics (when relevant)

## Running Tests

### Command Line
```bash
# Run all unit tests
xcodebuild test -scheme Vinylogue -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -quiet

# Run specific test class
xcodebuild test -scheme Vinylogue -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:VinylogueTests/CacheManagerTests

# Run specific test method
xcodebuild test -scheme Vinylogue -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:VinylogueTests/CacheManagerTests/testStoreAndRetrieveString
```

### Xcode
- Use Cmd+U to run all tests
- Use the Test Navigator to run specific test classes or methods
- Use the diamond icons in the gutter to run individual tests

### CI/CD Integration
Tests are designed to be deterministic and suitable for continuous integration:
- Use temporary resources for isolation
- Reset mock state between tests
- Handle concurrency properly
- Provide meaningful failure messages

## Debugging Tests

### Common Issues
1. **MainActor isolation**: Ensure proper async/await usage for UI components
2. **Mock setup**: Verify mocks are configured before test execution
3. **Resource cleanup**: Check for proper cleanup in tearDown methods
4. **Timing issues**: Use proper async/await patterns instead of sleep/wait

### Debugging Tips
- Use `print()` statements for debugging test flow
- Set breakpoints in test methods and mock implementations
- Check mock state and responses during debugging
- Verify test data creation and setup

This guide provides the foundation for understanding and contributing to the Vinylogue test suite. The architecture emphasizes clean, maintainable tests with proper isolation, comprehensive coverage, and helpful utilities for productivity.