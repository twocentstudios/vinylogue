import Dependencies
import Foundation
import Nuke
import XCTestDynamicOverlay

// MARK: - LastFM Client Dependency

extension LastFMClient: DependencyKey {
    static let liveValue: LastFMClientProtocol = LastFMClient()

    static let testValue: LastFMClientProtocol = MockLastFMClient()

    static let previewValue: LastFMClientProtocol = MockLastFMClient()
}

// MARK: - Mock LastFM Client for Testing/Previews

private struct MockLastFMClient: LastFMClientProtocol {
    func request<T: Codable>(_ endpoint: LastFMEndpoint) async throws -> T {
        // Return mock data based on endpoint type
        switch endpoint {
        case .userInfo:
            let mockResponse = UserInfoResponse(
                user: LastFMUserInfo(
                    name: "testuser",
                    realname: "Test User",
                    url: "https://last.fm/user/testuser",
                    image: [
                        LastFMImage(text: "https://example.com/user.jpg", size: "medium"),
                    ],
                    playcount: "1000",
                    registered: nil
                )
            )
            return mockResponse as! T

        case .userWeeklyChartList:
            let mockResponse = UserWeeklyChartListResponse(
                weeklychartlist: WeeklyChartList(
                    chart: [
                        ChartPeriod(from: "1234567890", to: "1234567890"),
                    ],
                    attr: WeeklyChartListAttributes(user: "testuser")
                )
            )
            return mockResponse as! T

        case .userWeeklyAlbumChart:
            let mockResponse = UserWeeklyAlbumChartResponse(
                weeklyalbumchart: WeeklyAlbumChart(
                    album: [
                        LastFMAlbumEntry(
                            artist: LastFMAlbumEntry.LastFMArtist(
                                mbid: nil,
                                name: "Mock Artist",
                                url: nil
                            ),
                            mbid: nil,
                            name: "Mock Album",
                            playcount: "10",
                            url: "https://example.com/album",
                            attr: LastFMAlbumEntry.LastFMAlbumAttr(rank: "1")
                        ),
                    ],
                    attr: WeeklyAlbumChartAttributes(
                        user: "testuser",
                        from: "1234567890",
                        to: "1234567890"
                    )
                )
            )
            return mockResponse as! T

        case .userFriends:
            let mockResponse = UserFriendsResponse(
                friends: LastFMFriends(
                    user: [
                        LastFMFriend(
                            name: "mockfriend",
                            realname: "Mock Friend",
                            url: "https://last.fm/user/mockfriend",
                            image: [
                                LastFMImage(text: "https://example.com/friend.jpg", size: "medium"),
                            ],
                            playcount: "500"
                        ),
                    ],
                    attr: UserFriendsAttributes(
                        user: "testuser",
                        totalPages: "1",
                        page: "1",
                        perPage: "50",
                        total: "1"
                    )
                )
            )
            return mockResponse as! T

        default:
            throw LastFMError.invalidResponse
        }
    }

    func fetchAlbumInfo(artist: String?, album: String?, mbid: String?, username: String?) async throws -> Album {
        Album(
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

extension DependencyValues {
    var lastFMClient: LastFMClientProtocol {
        get { self[LastFMClient.self] }
        set { self[LastFMClient.self] = newValue }
    }
}

// MARK: - Cache Manager Dependency

extension CacheManager: DependencyKey {
    static let liveValue = CacheManager()
}

extension DependencyValues {
    var cacheManager: CacheManager {
        get { self[CacheManager.self] }
        set { self[CacheManager.self] = newValue }
    }
}

// MARK: - Image Pipeline Dependency

private enum ImagePipelineKey: DependencyKey {
    static let liveValue = ImagePipeline.withTemporaryDiskCache()
}

extension DependencyValues {
    var imagePipeline: ImagePipeline {
        get { self[ImagePipelineKey.self] }
        set { self[ImagePipelineKey.self] = newValue }
    }
}
