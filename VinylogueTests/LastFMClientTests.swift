import Foundation
@testable import Vinylogue
import XCTest

final class LastFMClientTests: XCTestCase {
    var client: LastFMClient!

    override func setUpWithError() throws {
        client = LastFMClient()
    }

    override func tearDownWithError() throws {
        client = nil
    }

    // MARK: - Endpoint URL Building Tests

    func testUserWeeklyChartListEndpoint() {
        let endpoint = LastFMEndpoint.userWeeklyChartList(username: "testuser")
        let url = client.buildURL(for: endpoint)

        XCTAssertTrue(url.absoluteString.contains("method=user.getweeklychartlist"))
        XCTAssertTrue(url.absoluteString.contains("user=testuser"))
        XCTAssertTrue(url.absoluteString.contains("api_key="))
        XCTAssertTrue(url.absoluteString.contains("format=json"))
    }

    func testUserWeeklyAlbumChartEndpoint() {
        let from = Date(timeIntervalSince1970: 1640995200) // 2022-01-01
        let to = Date(timeIntervalSince1970: 1641600000) // 2022-01-08

        let endpoint = LastFMEndpoint.userWeeklyAlbumChart(username: "testuser", from: from, to: to)
        let url = client.buildURL(for: endpoint)

        XCTAssertTrue(url.absoluteString.contains("method=user.getweeklyalbumchart"))
        XCTAssertTrue(url.absoluteString.contains("user=testuser"))
        XCTAssertTrue(url.absoluteString.contains("from=1640995200"))
        XCTAssertTrue(url.absoluteString.contains("to=1641600000"))
    }

    func testAlbumInfoEndpointWithArtistAndAlbum() {
        let endpoint = LastFMEndpoint.albumInfo(artist: "Test Artist", album: "Test Album", mbid: nil, username: "testuser")
        let url = client.buildURL(for: endpoint)

        XCTAssertTrue(url.absoluteString.contains("method=album.getinfo"))
        XCTAssertTrue(url.absoluteString.contains("artist=Test%20Artist"))
        XCTAssertTrue(url.absoluteString.contains("album=Test%20Album"))
        XCTAssertTrue(url.absoluteString.contains("username=testuser"))
    }

    func testAlbumInfoEndpointWithMBID() {
        let endpoint = LastFMEndpoint.albumInfo(artist: nil, album: nil, mbid: "test-mbid-123", username: nil)
        let url = client.buildURL(for: endpoint)

        XCTAssertTrue(url.absoluteString.contains("method=album.getinfo"))
        XCTAssertTrue(url.absoluteString.contains("mbid=test-mbid-123"))
        XCTAssertFalse(url.absoluteString.contains("artist="))
        XCTAssertFalse(url.absoluteString.contains("album="))
    }

    func testUserInfoEndpoint() {
        let endpoint = LastFMEndpoint.userInfo(username: "testuser")
        let url = client.buildURL(for: endpoint)

        XCTAssertTrue(url.absoluteString.contains("method=user.getinfo"))
        XCTAssertTrue(url.absoluteString.contains("user=testuser"))
    }

    func testUserFriendsEndpoint() {
        let endpoint = LastFMEndpoint.userFriends(username: "testuser", limit: 50)
        let url = client.buildURL(for: endpoint)

        XCTAssertTrue(url.absoluteString.contains("method=user.getfriends"))
        XCTAssertTrue(url.absoluteString.contains("user=testuser"))
        XCTAssertTrue(url.absoluteString.contains("limit=50"))
    }

    // MARK: - Response Parsing Tests

    func testUserWeeklyChartListResponseParsing() throws {
        let json = """
        {
            "weeklychartlist": {
                "chart": [
                    {
                        "from": "1640995200",
                        "to": "1641600000"
                    },
                    {
                        "from": "1641600000",
                        "to": "1642204800"
                    }
                ],
                "@attr": {
                    "user": "testuser"
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(UserWeeklyChartListResponse.self, from: data)

        XCTAssertEqual(response.weeklychartlist.chart?.count, 2)
        XCTAssertEqual(response.weeklychartlist.attr.user, "testuser")
        XCTAssertEqual(response.weeklychartlist.chart?[0].from, "1640995200")
        XCTAssertEqual(response.weeklychartlist.chart?[0].to, "1641600000")
    }

    func testUserWeeklyAlbumChartResponseParsing() throws {
        let json = """
        {
            "weeklyalbumchart": {
                "album": [
                    {
                        "artist": {
                            "#text": "Test Artist",
                            "mbid": "",
                            "url": "https://www.last.fm/music/Test+Artist"
                        },
                        "name": "Test Album",
                        "mbid": "test-mbid",
                        "playcount": "42",
                        "@attr": {
                            "rank": "1"
                        },
                        "url": "https://www.last.fm/music/Test+Artist/Test+Album"
                    }
                ],
                "@attr": {
                    "user": "testuser",
                    "from": "1640995200",
                    "to": "1641600000"
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(UserWeeklyAlbumChartResponse.self, from: data)

        XCTAssertEqual(response.weeklyalbumchart.album?.count, 1)
        let album = response.weeklyalbumchart.album?[0]
        XCTAssertEqual(album?.name, "Test Album")
        XCTAssertEqual(album?.artist.name, "Test Artist")
        XCTAssertEqual(album?.playCount, 42)
        XCTAssertEqual(album?.rankNumber, 1)
    }

    func testAlbumInfoResponseParsing() throws {
        let json = """
        {
            "album": {
                "name": "Test Album",
                "artist": "Test Artist",
                "mbid": "test-mbid",
                "url": "https://www.last.fm/music/Test+Artist/Test+Album",
                "image": [
                    {
                        "#text": "https://lastfm.freetls.fastly.net/i/u/34s/test.jpg",
                        "size": "small"
                    },
                    {
                        "#text": "https://lastfm.freetls.fastly.net/i/u/300x300/test.jpg",
                        "size": "extralarge"
                    }
                ],
                "playcount": "1000",
                "userplaycount": 15,
                "wiki": {
                    "content": "Test album description"
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AlbumInfoResponse.self, from: data)

        let album = response.album
        XCTAssertEqual(album.name, "Test Album")
        XCTAssertEqual(album.artist, "Test Artist")
        XCTAssertEqual(album.totalPlayCount, 1000)
        XCTAssertEqual(album.userPlayCount, 15)
        XCTAssertEqual(album.description, "Test album description")
        XCTAssertEqual(album.imageURL, "https://lastfm.freetls.fastly.net/i/u/300x300/test.jpg")
    }

    func testUserInfoResponseParsing() throws {
        let json = """
        {
            "user": {
                "name": "testuser",
                "realname": "Test User",
                "url": "https://www.last.fm/user/testuser",
                "image": [
                    {
                        "#text": "https://lastfm.freetls.fastly.net/i/u/300x300/avatar.jpg",
                        "size": "extralarge"
                    }
                ],
                "playcount": "50000"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(UserInfoResponse.self, from: data)

        let user = response.user
        XCTAssertEqual(user.name, "testuser")
        XCTAssertEqual(user.realname, "Test User")
        XCTAssertEqual(user.totalPlayCount, 50000)
        XCTAssertEqual(user.imageURL, "https://lastfm.freetls.fastly.net/i/u/300x300/avatar.jpg")
    }

    func testUserFriendsResponseParsing() throws {
        let json = """
        {
            "friends": {
                "user": [
                    {
                        "name": "friend1",
                        "realname": "Friend One",
                        "url": "https://www.last.fm/user/friend1",
                        "playcount": "25000"
                    },
                    {
                        "name": "friend2",
                        "realname": "Friend Two",
                        "url": "https://www.last.fm/user/friend2",
                        "playcount": "30000"
                    }
                ],
                "@attr": {
                    "user": "testuser",
                    "totalPages": "1",
                    "page": "1",
                    "perPage": "50",
                    "total": "2"
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(UserFriendsResponse.self, from: data)

        XCTAssertEqual(response.friends.user.count, 2)
        XCTAssertEqual(response.friends.attr.user, "testuser")

        let friend1 = response.friends.user[0]
        XCTAssertEqual(friend1.name, "friend1")
        XCTAssertEqual(friend1.realname, "Friend One")
        XCTAssertEqual(friend1.totalPlayCount, 25000)
    }

    // MARK: - Error Handling Tests

    func testLastFMErrorResponseParsing() throws {
        let json = """
        {
            "error": 6,
            "message": "User not found"
        }
        """

        let data = json.data(using: .utf8)!
        let errorResponse = try JSONDecoder().decode(LastFMErrorResponse.self, from: data)

        XCTAssertEqual(errorResponse.error, 6)
        XCTAssertEqual(errorResponse.message, "User not found")
    }

    func testErrorMapping() {
        XCTAssertEqual(client.mapLastFMError(code: 6, message: "User not found"), .userNotFound)
        XCTAssertEqual(client.mapLastFMError(code: 10, message: "Invalid API key"), .invalidAPIKey)
        XCTAssertEqual(client.mapLastFMError(code: 11, message: "Service unavailable"), .serviceUnavailable)
        XCTAssertEqual(client.mapLastFMError(code: 16, message: "Service unavailable"), .serviceUnavailable)

        if case let .apiError(code, message) = client.mapLastFMError(code: 999, message: "Unknown error") {
            XCTAssertEqual(code, 999)
            XCTAssertEqual(message, "Unknown error")
        } else {
            XCTFail("Expected .apiError case")
        }
    }

    // MARK: - Model Tests

    func testWeeklyChartDateConversion() {
        let period = ChartPeriod(from: "1640995200", to: "1641600000")

        XCTAssertEqual(period.fromDate.timeIntervalSince1970, 1640995200)
        XCTAssertEqual(period.toDate.timeIntervalSince1970, 1641600000)
    }

    func testAlbumModelDetailLoading() {
        var album = Album(
            name: "Test Album",
            artist: "Test Artist",
            imageURL: nil,
            playCount: 10,
            rank: 1,
            url: nil,
            mbid: nil
        )

        XCTAssertFalse(album.isDetailLoaded)

        album.description = "Test description"
        album.isDetailLoaded = true

        XCTAssertTrue(album.isDetailLoaded)
        XCTAssertEqual(album.description, "Test description")
    }

    // MARK: - Description Cleanup Tests

    func testCleanupDescriptionRemovesLastFMLink() {
        let description = "Postcard From A Living Hell is the full-length debut studio album from Australian pop punk band RedHook. It was independently released on April 21, 2023. <a href=\"https://www.last.fm/music/RedHook/Postcard+From+A+Living+Hell\">Read more on Last.fm</a>."

        let cleaned = client.cleanupDescription(description)
        let expected = "Postcard From A Living Hell is the full-length debut studio album from Australian pop punk band RedHook. It was independently released on April 21, 2023."

        XCTAssertEqual(cleaned, expected)
    }

    func testCleanupDescriptionRemovesLastFMLinkWithoutTrailingPeriod() {
        let description = "Test album description. <a href=\"https://www.last.fm/music/Artist/Album\">Read more on Last.fm</a>"

        let cleaned = client.cleanupDescription(description)
        let expected = "Test album description."

        XCTAssertEqual(cleaned, expected)
    }

    func testCleanupDescriptionWithNilInput() {
        let cleaned = client.cleanupDescription(nil)

        XCTAssertNil(cleaned)
    }

    func testCleanupDescriptionWithEmptyStringAfterCleanup() {
        let description = "<a href=\"https://www.last.fm/music/Artist/Album\">Read more on Last.fm</a>"

        let cleaned = client.cleanupDescription(description)

        XCTAssertNil(cleaned)
    }

    func testCleanupDescriptionWithNoLastFMLink() {
        let description = "This is a normal album description without any Last.fm links."

        let cleaned = client.cleanupDescription(description)

        XCTAssertEqual(cleaned, description)
    }

    func testCleanupDescriptionWithMultipleSpacesAndWhitespace() {
        let description = "   Test description.   <a href=\"https://www.last.fm/music/Artist/Album\">Read more on Last.fm</a>   "

        let cleaned = client.cleanupDescription(description)
        let expected = "Test description."

        XCTAssertEqual(cleaned, expected)
    }

    func testCleanupDescriptionRemovesCreativeCommonsText() {
        let description = "This is an album description. User-contributed text is available under the Creative Commons By-SA License; additional terms may apply."

        let cleaned = client.cleanupDescription(description)
        let expected = "This is an album description."

        XCTAssertEqual(cleaned, expected)
    }

    func testCleanupDescriptionRemovesBothLastFmLinkAndCreativeCommonsText() {
        let description = "Great album description. <a href=\"https://www.last.fm/music/Artist/Album\">Read more on Last.fm</a> User-contributed text is available under the Creative Commons By-SA License; additional terms may apply."

        let cleaned = client.cleanupDescription(description)
        let expected = "Great album description."

        XCTAssertEqual(cleaned, expected)
    }
}
