import Foundation
@testable import Vinylogue
import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func setupApp(testName: String? = nil) throws {
        // Disable hardware keyboard to prevent issues with screenshots
        app = XCUIApplication()
        app.launchArguments = ["--screenshot-testing"]

        // Set up UI test environment similar to SyncUps pattern
        if let testName {
            app.launchEnvironment["UI_TEST_NAME"] = testName
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testUsersListViewScreenshot() throws {
        // Set up the app with test name for environment detection
        try setupApp(testName: "testUsersListViewScreenshot")

        // Launch the app
        app.launch()

        // Wait for the app to load and navigate to users list
        let usersListNavigationTitle = app.navigationBars["scrobblers"]
        XCTAssertTrue(usersListNavigationTitle.waitForExistence(timeout: 10.0), "Users list should be visible")

        // Wait a moment for all content to load
        Thread.sleep(forTimeInterval: 2.0)

        // Take screenshot for Users List View
        takeScreenshot(named: "01-UsersListView")
    }

    @MainActor
    func testMultipleScreenshots() throws {
        // Set up the app with test name for environment detection
        try setupApp(testName: "testMultipleScreenshots")

        // This test can be extended to capture multiple app screens
        app.launch()

        // Capture main screen
        let usersListNavigationTitle = app.navigationBars["scrobblers"]
        XCTAssertTrue(usersListNavigationTitle.waitForExistence(timeout: 10.0), "Users list should be visible")
        Thread.sleep(forTimeInterval: 2.0)
        takeScreenshot(named: "01-UsersListView-Light")

        // Future: Add more screens here
        // navigateToSettings()
        // takeScreenshot(named: "02-Settings")
    }

    // MARK: - Helper Methods

    /// Takes a screenshot and attaches it to the test result with the given name
    @MainActor
    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
