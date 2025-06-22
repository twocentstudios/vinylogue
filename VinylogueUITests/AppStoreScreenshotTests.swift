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
        
        // Wait for user data to be fully loaded (friends should be visible)
        let firstFriend = app.buttons["BobbyStompy"]
        XCTAssertTrue(firstFriend.waitForExistence(timeout: 8.0), "First friend should be visible")
        
        takeScreenshot(named: "01-UsersListView")

        // Navigate to first user's weekly albums
        let firstUser = app.buttons["ybsc"]
        XCTAssertTrue(firstUser.waitForExistence(timeout: 5.0), "First user should be visible")
        firstUser.tap()

        // Screenshot 2: WeeklyAlbumsView with mock date (2023-06-20)
        let playsText = app.staticTexts["plays"]
        let albumDataExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: playsText
        )
        wait(for: [albumDataExpectation], timeout: 10.0)
        
        // Wait for album images to load (wait until no images are in loading state)
        let loadingImages = app.images.matching(identifier: "imageLoading")
        let imagesLoadedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count == 0"),
            object: loadingImages
        )
        wait(for: [imagesLoadedExpectation], timeout: 15.0)
        takeScreenshot(named: "02-WeeklyAlbumsView")

        // Navigate to first album in the list
        XCTAssertTrue(playsText.waitForExistence(timeout: 10.0), "Album with play count should be visible")
        let albumButtons = app.buttons.allElementsBoundByIndex
        var firstAlbumButton: XCUIElement?
        for button in albumButtons {
            if button.staticTexts["THRICE"].exists {
                firstAlbumButton = button
                break
            }
        }
        guard let albumButton = firstAlbumButton else {
            XCTFail("Should find an album button with plays text")
            return
        }
        albumButton.tap()

        // Screenshot 3: AlbumDetailView
        let playsLabel = app.staticTexts["plays"]
        let contentLoadedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: playsLabel
        )
        wait(for: [contentLoadedExpectation], timeout: 8.0)
        let anyText = app.staticTexts.firstMatch
        _ = anyText.waitForExistence(timeout: 3.0)
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
