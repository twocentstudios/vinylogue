import Dependencies
import Nuke
import Sharing
import SwiftUI

@main
struct VinylogueApp: App {
    static let rootStore = RootStore()

    init() {
        setUpForUITest()
    }

    var body: some Scene {
        WindowGroup {
            if isTesting, !isScreenshotTesting {
                EmptyView()
            } else {
                RootView(store: Self.rootStore)
                    .task {
                        if !isScreenshotTesting {
                            #if DEBUG
                                @Dependency(\.cacheManager) var cacheManager
                                try! await cacheManager.clearCache()
                            #endif
                        }
                    }
            }
        }
    }
}

// MARK: - UI Test Setup

private func setUpForUITest() {
    guard let testName = ProcessInfo.processInfo.environment["UI_TEST_NAME"]
    else {
        return
    }

    // Set up dependencies for UI testing based on test name
    switch testName {
    case "testUsersListViewScreenshot", "testMultipleScreenshots", "testGenerateAppStoreScreenshots":
        setupScreenshotTestDependencies()
    default:
        print("Unrecognized UI test: \(testName)")
    }
}

private func setupScreenshotTestDependencies() {
    // Override dependencies to provide test data instead of modifying @Shared directly
    prepareDependencies {
        // Use in-memory storage for testing to avoid persisting test data
        $0.defaultFileStorage = .inMemory

        // Create a temporary UserDefaults for testing
        $0.defaultAppStorage = UserDefaults(
            suiteName: "\(NSTemporaryDirectory())\(UUID().uuidString)"
        )!

        // Override date for WeeklyAlbumsView to show specific date
        $0.date = .constant(Date(timeIntervalSince1970: 1749344207)) // Week 23 of 2024
    }

    // Set up test data in the overridden storage
    setupTestData()

    // Set pixelation state based on environment variable
    setupPixelationState()
}

private func setupTestData() {
    // Set up current user for screenshot tests
    @Shared(.currentUser) var currentUsername: String?
    $currentUsername.withLock { $0 = "ybsc" }

    // Set up friends data for screenshot tests
    let testFriends = [
        User(username: "BobbyStompy", realName: "Bobby Stompy", imageURL: nil, url: nil, playCount: 15432),
        User(username: "slippydrums", realName: "Slippy Drums", imageURL: nil, url: nil, playCount: 12890),
        User(username: "lackenir", realName: "Lacke Nir", imageURL: nil, url: nil, playCount: 23456),
        User(username: "itschinatown", realName: "Its Chinatown", imageURL: nil, url: nil, playCount: 8901),
        User(username: "esheihk", realName: "Esheihk", imageURL: nil, url: nil, playCount: 5678),
    ]

    @Shared(.curatedFriends) var curatedFriends: [User]
    $curatedFriends.withLock { $0 = testFriends }
}

private func setupPixelationState() {
    // Read pixelation setting from environment variable
    let pixelationEnabled = ProcessInfo.processInfo.environment["PIXELATION_ENABLED"] == "true"

    @Shared(.pixelationEnabled) var pixelationEnabledState: Bool
    $pixelationEnabledState.withLock { $0 = pixelationEnabled }
}
