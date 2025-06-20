import Foundation
@testable import Vinylogue
import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func setupApp() throws {
        // Disable hardware keyboard to prevent issues with screenshots
        app = XCUIApplication()
        app.launchArguments = ["--screenshot-testing"]

        // Set up test data as launch environment
        app.launchEnvironment["CURRENT_USER"] = "ybsc"
        app.launchEnvironment["FRIENDS_DATA"] = createFriendsJSON()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testUsersListViewScreenshot() throws {
        // Set up the app
        try setupApp()

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
        // Set up the app
        try setupApp()

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

    /// Creates JSON string for test friends data
    private func createFriendsJSON() -> String {
        let friends = [
            ["username": "BobbyStompy", "realName": "Bobby Stompy", "playCount": 15432],
            ["username": "slippydrums", "realName": "Slippy Drums", "playCount": 12890],
            ["username": "lackenir", "realName": "Lacke Nir", "playCount": 23456],
            ["username": "itschinatown", "realName": "Its Chinatown", "playCount": 8901],
            ["username": "esheihk", "realName": "Esheihk", "playCount": 5678],
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: friends, options: [])
            return String(data: jsonData, encoding: .utf8) ?? "[]"
        } catch {
            return "[]"
        }
    }
}
