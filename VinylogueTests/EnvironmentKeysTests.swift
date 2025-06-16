import Nuke
import SwiftUI
@testable import Vinylogue
import XCTest

final class EnvironmentKeysTests: XCTestCase {
    // MARK: - Environment Values Tests

    func testLastFMClientEnvironmentKey() {
        // Given
        var environmentValues = EnvironmentValues()
        let testClient = LastFMClient()

        // When
        environmentValues.lastFMClient = testClient
        let retrievedClient = environmentValues.lastFMClient

        // Then
        XCTAssertNotNil(retrievedClient)
        XCTAssertTrue(retrievedClient is LastFMClient)
    }

    func testImagePipelineEnvironmentKey() {
        // Given
        var environmentValues = EnvironmentValues()
        let testPipeline = ImagePipeline.shared

        // When
        environmentValues.imagePipeline = testPipeline
        let retrievedPipeline = environmentValues.imagePipeline

        // Then
        XCTAssertNotNil(retrievedPipeline)
        // Note: ImagePipeline doesn't conform to Equatable, so we just test it's not nil
    }

    func testPlayCountFilterEnvironmentKey() {
        // Given
        var environmentValues = EnvironmentValues()
        let testFilter = 8

        // When
        environmentValues.playCountFilter = testFilter
        let retrievedFilter = environmentValues.playCountFilter

        // Then
        XCTAssertEqual(retrievedFilter, testFilter)
    }

    func testCurrentUserEnvironmentKey() {
        // Given
        var environmentValues = EnvironmentValues()
        let testUser = User(username: "testuser", realName: "Test User", imageURL: nil, url: nil, playCount: 1000)

        // When
        environmentValues.currentUser = testUser
        let retrievedUser = environmentValues.currentUser

        // Then
        XCTAssertEqual(retrievedUser?.username, testUser.username)
        XCTAssertEqual(retrievedUser?.realName, testUser.realName)
        XCTAssertEqual(retrievedUser?.playCount, testUser.playCount)
    }

    func testCurrentUserEnvironmentKeyNil() {
        // Given
        var environmentValues = EnvironmentValues()

        // When
        environmentValues.currentUser = nil
        let retrievedUser = environmentValues.currentUser

        // Then
        XCTAssertNil(retrievedUser)
    }

    func testCuratedFriendsEnvironmentKey() {
        // Given
        var environmentValues = EnvironmentValues()
        let testFriends = [
            User(username: "friend1", realName: "Friend One", imageURL: nil, url: nil, playCount: 500),
            User(username: "friend2", realName: "Friend Two", imageURL: nil, url: nil, playCount: 750),
            User(username: "friend3", realName: "Friend Three", imageURL: nil, url: nil, playCount: 200),
        ]

        // When
        environmentValues.curatedFriends = testFriends
        let retrievedFriends = environmentValues.curatedFriends

        // Then
        XCTAssertEqual(retrievedFriends.count, 3)
        XCTAssertEqual(retrievedFriends[0].username, "friend1")
        XCTAssertEqual(retrievedFriends[1].username, "friend2")
        XCTAssertEqual(retrievedFriends[2].username, "friend3")
    }

    func testCuratedFriendsEnvironmentKeyEmpty() {
        // Given
        var environmentValues = EnvironmentValues()
        let emptyFriends: [User] = []

        // When
        environmentValues.curatedFriends = emptyFriends
        let retrievedFriends = environmentValues.curatedFriends

        // Then
        XCTAssertTrue(retrievedFriends.isEmpty)
    }

    // MARK: - Default Values Tests

    func testDefaultLastFMClient() {
        // Given
        let environmentValues = EnvironmentValues()

        // When
        let defaultClient = environmentValues.lastFMClient

        // Then
        XCTAssertNotNil(defaultClient)
        XCTAssertTrue(defaultClient is LastFMClient)
    }

    func testDefaultImagePipeline() {
        // Given
        let environmentValues = EnvironmentValues()

        // When
        let defaultPipeline = environmentValues.imagePipeline

        // Then
        XCTAssertNotNil(defaultPipeline)
        // Note: ImagePipeline doesn't conform to Equatable, so we just test it's not nil
    }

    func testDefaultPlayCountFilter() {
        // Given
        let environmentValues = EnvironmentValues()

        // When
        let defaultFilter = environmentValues.playCountFilter

        // Then
        XCTAssertEqual(defaultFilter, 1)
    }

    func testDefaultCurrentUser() {
        // Given
        let environmentValues = EnvironmentValues()

        // When
        let defaultUser = environmentValues.currentUser

        // Then
        XCTAssertNil(defaultUser)
    }

    func testDefaultCuratedFriends() {
        // Given
        let environmentValues = EnvironmentValues()

        // When
        let defaultFriends = environmentValues.curatedFriends

        // Then
        XCTAssertTrue(defaultFriends.isEmpty)
    }

    // MARK: - Multiple Updates Tests

    func testMultiplePlayCountFilterUpdates() {
        // Given
        var environmentValues = EnvironmentValues()

        // When & Then
        environmentValues.playCountFilter = 2
        XCTAssertEqual(environmentValues.playCountFilter, 2)

        environmentValues.playCountFilter = 16
        XCTAssertEqual(environmentValues.playCountFilter, 16)

        environmentValues.playCountFilter = 0
        XCTAssertEqual(environmentValues.playCountFilter, 0)
    }

    func testMultipleFriendsUpdates() {
        // Given
        var environmentValues = EnvironmentValues()
        let friends1 = [User(username: "user1", realName: nil, imageURL: nil, url: nil, playCount: nil)]
        let friends2 = [
            User(username: "user2", realName: nil, imageURL: nil, url: nil, playCount: nil),
            User(username: "user3", realName: nil, imageURL: nil, url: nil, playCount: nil),
        ]

        // When & Then
        environmentValues.curatedFriends = friends1
        XCTAssertEqual(environmentValues.curatedFriends.count, 1)
        XCTAssertEqual(environmentValues.curatedFriends[0].username, "user1")

        environmentValues.curatedFriends = friends2
        XCTAssertEqual(environmentValues.curatedFriends.count, 2)
        XCTAssertEqual(environmentValues.curatedFriends[0].username, "user2")
        XCTAssertEqual(environmentValues.curatedFriends[1].username, "user3")

        environmentValues.curatedFriends = []
        XCTAssertTrue(environmentValues.curatedFriends.isEmpty)
    }
}
