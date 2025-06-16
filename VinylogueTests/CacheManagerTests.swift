@testable import Vinylogue
import XCTest

@MainActor
final class CacheManagerTests: XCTestCase {
    private var cacheManager: CacheManager!

    override func setUp() {
        super.setUp()
        cacheManager = CacheManager()
    }

    override func tearDown() {
        super.tearDown()
        // Clean up any test cache files
        Task {
            try? await cacheManager.remove(key: "test_key")
            try? await cacheManager.remove(key: "user_test")
            try? await cacheManager.remove(key: "album_test")
        }
        cacheManager = nil
    }

    // MARK: - Basic Store and Retrieve Tests

    func testStoreAndRetrieveString() async throws {
        // Given
        let testString = "Hello, Vinylogue!"
        let key = "test_key"

        // When
        try await cacheManager.store(testString, key: key)
        let retrieved: String? = try await cacheManager.retrieve(String.self, key: key)

        // Then
        XCTAssertEqual(retrieved, testString)
    }

    func testStoreAndRetrieveUser() async throws {
        // Given
        let testUser = User(username: "testuser", realName: "Test User", imageURL: "http://example.com", url: "http://last.fm/user/testuser", playCount: 1000)
        let key = "user_test"

        // When
        try await cacheManager.store(testUser, key: key)
        let retrieved: User? = try await cacheManager.retrieve(User.self, key: key)

        // Then
        XCTAssertEqual(retrieved?.username, testUser.username)
        XCTAssertEqual(retrieved?.realName, testUser.realName)
        XCTAssertEqual(retrieved?.imageURL, testUser.imageURL)
        XCTAssertEqual(retrieved?.url, testUser.url)
        XCTAssertEqual(retrieved?.playCount, testUser.playCount)
    }

    func testStoreAndRetrieveAlbum() async throws {
        // Given
        let testAlbum = Album(name: "Test Album", artist: "Test Artist", imageURL: "http://example.com/album.jpg", playCount: 50, rank: 1, url: "http://last.fm/music/Test+Artist/Test+Album", mbid: "test-mbid")
        let key = "album_test"

        // When
        try await cacheManager.store(testAlbum, key: key)
        let retrieved: Album? = try await cacheManager.retrieve(Album.self, key: key)

        // Then
        XCTAssertEqual(retrieved?.name, testAlbum.name)
        XCTAssertEqual(retrieved?.artist, testAlbum.artist)
        XCTAssertEqual(retrieved?.imageURL, testAlbum.imageURL)
        XCTAssertEqual(retrieved?.playCount, testAlbum.playCount)
        XCTAssertEqual(retrieved?.rank, testAlbum.rank)
        XCTAssertEqual(retrieved?.url, testAlbum.url)
        XCTAssertEqual(retrieved?.mbid, testAlbum.mbid)
    }

    // MARK: - Edge Cases

    func testRetrieveNonExistentKey() async throws {
        // When
        let retrieved: String? = try await cacheManager.retrieve(String.self, key: "nonexistent_key")

        // Then
        XCTAssertNil(retrieved)
    }

    func testRemoveExistingKey() async throws {
        // Given
        let testData = "Test Data"
        let key = "test_key"
        try await cacheManager.store(testData, key: key)

        // When
        try await cacheManager.remove(key: key)
        let retrieved: String? = try await cacheManager.retrieve(String.self, key: key)

        // Then
        XCTAssertNil(retrieved)
    }

    func testRemoveNonExistentKey() async throws {
        // This should not throw an error
        try await cacheManager.remove(key: "nonexistent_key")
    }

    // MARK: - Array Storage

    func testStoreAndRetrieveArray() async throws {
        // Given
        let testUsers = [
            User(username: "user1", realName: "User One", imageURL: nil, url: nil, playCount: 100),
            User(username: "user2", realName: "User Two", imageURL: nil, url: nil, playCount: 200),
            User(username: "user3", realName: "User Three", imageURL: nil, url: nil, playCount: 300),
        ]
        let key = "users_array"

        // When
        try await cacheManager.store(testUsers, key: key)
        let retrieved: [User]? = try await cacheManager.retrieve([User].self, key: key)

        // Then
        XCTAssertEqual(retrieved?.count, 3)
        XCTAssertEqual(retrieved?[0].username, "user1")
        XCTAssertEqual(retrieved?[1].username, "user2")
        XCTAssertEqual(retrieved?[2].username, "user3")

        // Cleanup
        try await cacheManager.remove(key: key)
    }
}

// MARK: - ChartCache Tests

@MainActor
final class ChartCacheTests: XCTestCase {
    private var chartCache: ChartCache!

    override func setUp() {
        super.setUp()
        chartCache = ChartCache()
    }

    override func tearDown() {
        super.tearDown()
        chartCache = nil
    }

    func testChartCacheSaveAndLoad() async throws {
        // Given
        let testAlbums = [
            Album(name: "Album 1", artist: "Artist 1", imageURL: nil, playCount: 10, rank: 1, url: nil, mbid: nil),
            Album(name: "Album 2", artist: "Artist 2", imageURL: nil, playCount: 8, rank: 2, url: nil, mbid: nil),
        ]
        let albumsData = try JSONEncoder().encode(testAlbums)
        let user = "testuser"
        let fromDate = Date(timeIntervalSince1970: 1000000)
        let toDate = Date(timeIntervalSince1970: 1000000 + 604800) // One week later

        // When
        try await chartCache.save(albumsData, user: user, from: fromDate, to: toDate)
        let loadedData = try await chartCache.load(user: user, from: fromDate, to: toDate)

        // Then
        XCTAssertNotNil(loadedData)

        let loadedAlbums = try JSONDecoder().decode([Album].self, from: loadedData!)
        XCTAssertEqual(loadedAlbums.count, 2)
        XCTAssertEqual(loadedAlbums[0].name, "Album 1")
        XCTAssertEqual(loadedAlbums[1].name, "Album 2")
    }

    func testChartCacheLoadNonExistent() async throws {
        // Given
        let user = "nonexistentuser"
        let fromDate = Date(timeIntervalSince1970: 2000000)
        let toDate = Date(timeIntervalSince1970: 2000000 + 604800)

        // When
        let loadedData = try await chartCache.load(user: user, from: fromDate, to: toDate)

        // Then
        XCTAssertNil(loadedData)
    }
}
