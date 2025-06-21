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
    func testGenerateAppStoreScreenshots() throws {
        // This test generates all 3 required App Store screenshots
        try setupApp(testName: "testGenerateAppStoreScreenshots")
        app.launch()

        // Screenshot 1: UsersListView with mock data
        let usersListNavigationTitle = app.navigationBars["scrobblers"]
        XCTAssertTrue(usersListNavigationTitle.waitForExistence(timeout: 10.0), "Users list should be visible")
        Thread.sleep(forTimeInterval: 2.0)
        takeScreenshot(named: "01-UsersListView")

        // Navigate to first user's weekly albums
        let firstUser = app.buttons["ybsc"]
        XCTAssertTrue(firstUser.waitForExistence(timeout: 5.0), "First user should be visible")
        firstUser.tap()

        // Screenshot 2: WeeklyAlbumsView with mock date (2023-06-20)
        // Wait for weekly albums view to load by looking for chart-specific content
        Thread.sleep(forTimeInterval: 3.0) // Wait for navigation and data loading
        Thread.sleep(forTimeInterval: 3.0) // Wait for data to load
        takeScreenshot(named: "02-WeeklyAlbumsView")

        // Navigate to first album in the list
        // Look for album row by finding text with "plays" (unique to album rows)
        let playsText = app.staticTexts["plays"]
        XCTAssertTrue(playsText.waitForExistence(timeout: 5.0), "Album with play count should be visible")

        // Tap the first album row by finding the button containing "plays"
        let albumButtons = app.buttons.allElementsBoundByIndex
        var albumTapped = false
        for button in albumButtons {
            if button.staticTexts["plays"].exists {
                button.tap()
                albumTapped = true
                break
            }
        }
        XCTAssertTrue(albumTapped, "Should be able to tap an album row")

        // Screenshot 3: AlbumDetailView
        // Wait for album detail view to load
        Thread.sleep(forTimeInterval: 3.0)
        takeScreenshot(named: "03-AlbumDetailView")
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

        // Log screenshot taken for debugging
        print("📸 Screenshot taken: \(name)")
    }
}
