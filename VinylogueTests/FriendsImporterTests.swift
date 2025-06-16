import Foundation
@testable import Vinylogue
import XCTest

@MainActor
final class FriendsImporterTests: XCTestCase {
    var friendsImporter: FriendsImporter!
    var mockLastFMClient: MockLastFMClient!
    
    override func setUpWithError() throws {
        mockLastFMClient = MockLastFMClient()
        friendsImporter = FriendsImporter(lastFMClient: mockLastFMClient)
    }
    
    override func tearDownWithError() throws {
        friendsImporter = nil
        mockLastFMClient = nil
    }
    
    // MARK: - Import Friends Tests
    
    func testImportFriendsSuccess() async {
        // Given: Mock API response with friends
        let mockResponse = UserFriendsResponse(
            friends: LastFMFriends(
                user: [
                    LastFMFriend(
                        name: "testfriend1",
                        realname: "Test Friend One",
                        url: "https://last.fm/user/testfriend1",
                        image: [
                            LastFMImage(text: "https://example.com/image1.jpg", size: "medium"),
                            LastFMImage(text: "https://example.com/image1_large.jpg", size: "large")
                        ],
                        playcount: "1500"
                    ),
                    LastFMFriend(
                        name: "testfriend2",
                        realname: nil,
                        url: "https://last.fm/user/testfriend2",
                        image: nil,
                        playcount: "750"
                    )
                ],
                attr: UserFriendsAttributes(
                    user: "testuser",
                    totalPages: "1",
                    page: "1",
                    perPage: "50",
                    total: "2"
                )
            )
        )
        
        mockLastFMClient.mockResponse = mockResponse
        
        // When: Importing friends
        await friendsImporter.importFriends(for: "testuser")
        
        // Then: Friends are loaded correctly
        XCTAssertFalse(friendsImporter.isLoading)
        XCTAssertNil(friendsImporter.importError)
        XCTAssertEqual(friendsImporter.friends.count, 2)
        
        let friend1 = friendsImporter.friends[0]
        XCTAssertEqual(friend1.username, "testfriend1")
        XCTAssertEqual(friend1.realName, "Test Friend One")
        XCTAssertEqual(friend1.imageURL, "https://example.com/image1_large.jpg") // Uses largest image
        XCTAssertEqual(friend1.url, "https://last.fm/user/testfriend1")
        XCTAssertEqual(friend1.playCount, 1500)
        
        let friend2 = friendsImporter.friends[1]
        XCTAssertEqual(friend2.username, "testfriend2")
        XCTAssertNil(friend2.realName)
        XCTAssertNil(friend2.imageURL)
        XCTAssertEqual(friend2.url, "https://last.fm/user/testfriend2")
        XCTAssertEqual(friend2.playCount, 750)
    }
    
    func testImportFriendsNetworkError() async {
        // Given: Mock API error
        mockLastFMClient.mockError = LastFMError.networkUnavailable
        
        // When: Importing friends
        await friendsImporter.importFriends(for: "testuser")
        
        // Then: Error is handled correctly
        XCTAssertFalse(friendsImporter.isLoading)
        XCTAssertNotNil(friendsImporter.importError)
        XCTAssertTrue(friendsImporter.friends.isEmpty)
        
        if case LastFMError.networkUnavailable = friendsImporter.importError! {
            // Expected error type
        } else {
            XCTFail("Expected network unavailable error")
        }
    }
    
    func testImportFriendsUserNotFound() async {
        // Given: Mock API user not found error
        mockLastFMClient.mockError = LastFMError.userNotFound
        
        // When: Importing friends
        await friendsImporter.importFriends(for: "nonexistentuser")
        
        // Then: Error is handled correctly
        XCTAssertFalse(friendsImporter.isLoading)
        XCTAssertNotNil(friendsImporter.importError)
        XCTAssertTrue(friendsImporter.friends.isEmpty)
    }
    
    func testImportFriendsEmptyResponse() async {
        // Given: Mock API response with no friends
        let mockResponse = UserFriendsResponse(
            friends: LastFMFriends(
                user: [],
                attr: UserFriendsAttributes(
                    user: "testuser",
                    totalPages: "1",
                    page: "1",
                    perPage: "50",
                    total: "0"
                )
            )
        )
        
        mockLastFMClient.mockResponse = mockResponse
        
        // When: Importing friends
        await friendsImporter.importFriends(for: "testuser")
        
        // Then: Empty list is handled correctly
        XCTAssertFalse(friendsImporter.isLoading)
        XCTAssertNil(friendsImporter.importError)
        XCTAssertTrue(friendsImporter.friends.isEmpty)
    }
    
    // MARK: - Friend Filtering Tests
    
    func testGetNewFriendsExcludingCurated() {
        // Given: Imported friends and curated friends
        let importedFriends = [
            User(username: "friend1", realName: "Friend One", imageURL: nil, url: nil, playCount: 100),
            User(username: "friend2", realName: "Friend Two", imageURL: nil, url: nil, playCount: 200),
            User(username: "friend3", realName: "Friend Three", imageURL: nil, url: nil, playCount: 300)
        ]
        
        let curatedFriends = [
            User(username: "friend1", realName: "Friend One", imageURL: nil, url: nil, playCount: 100),
            User(username: "otherfriend", realName: "Other Friend", imageURL: nil, url: nil, playCount: 50)
        ]
        
        friendsImporter.friends = importedFriends
        
        // When: Getting new friends excluding curated ones
        let newFriends = friendsImporter.getNewFriends(excluding: curatedFriends)
        
        // Then: Only non-curated friends are returned
        XCTAssertEqual(newFriends.count, 2)
        XCTAssertTrue(newFriends.contains { $0.username == "friend2" })
        XCTAssertTrue(newFriends.contains { $0.username == "friend3" })
        XCTAssertFalse(newFriends.contains { $0.username == "friend1" }) // Already curated
    }
    
    func testGetNewFriendsAllAlreadyCurated() {
        // Given: All imported friends are already curated
        let importedFriends = [
            User(username: "friend1", realName: "Friend One", imageURL: nil, url: nil, playCount: 100),
            User(username: "friend2", realName: "Friend Two", imageURL: nil, url: nil, playCount: 200)
        ]
        
        let curatedFriends = importedFriends // Same friends
        
        friendsImporter.friends = importedFriends
        
        // When: Getting new friends
        let newFriends = friendsImporter.getNewFriends(excluding: curatedFriends)
        
        // Then: No new friends returned
        XCTAssertTrue(newFriends.isEmpty)
    }
    
    // MARK: - Clear Friends Test
    
    func testClearFriends() {
        // Given: Friends list with data and an error
        friendsImporter.friends = [
            User(username: "friend1", realName: "Friend One", imageURL: nil, url: nil, playCount: 100)
        ]
        friendsImporter.importError = LastFMError.networkUnavailable
        
        // When: Clearing friends
        friendsImporter.clearFriends()
        
        // Then: Friends and error are cleared
        XCTAssertTrue(friendsImporter.friends.isEmpty)
        XCTAssertNil(friendsImporter.importError)
    }
}

// MARK: - Mock LastFM Client

class MockLastFMClient: LastFMClientProtocol {
    var mockResponse: Any?
    var mockError: Error?
    
    func request<T: Codable>(_ endpoint: LastFMEndpoint) async throws -> T {
        if let error = mockError {
            throw error
        }
        
        guard let response = mockResponse as? T else {
            throw LastFMError.invalidResponse
        }
        
        return response
    }
    
    func fetchAlbumInfo(artist: String?, album: String?, mbid: String?, username: String?) async throws -> Album {
        // Simple mock implementation for testing
        return Album(
            name: album ?? "Mock Album",
            artist: artist ?? "Mock Artist",
            imageURL: "https://example.com/mock.jpg",
            playCount: 0,
            rank: nil,
            url: nil,
            mbid: mbid
        )
    }
}