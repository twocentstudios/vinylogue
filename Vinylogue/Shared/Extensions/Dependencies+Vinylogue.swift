import Dependencies
import Foundation
import Nuke
import XCTestDynamicOverlay

// MARK: - LastFM Client Dependency

extension LastFMClient: DependencyKey {
    static let liveValue: LastFMClientProtocol = LastFMClient()

    // Note: Tests should override this with TestLastFMClient using withDependencies
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
            // Generate realistic chart periods for the last 2 years
            let now = Date()
            let calendar = Calendar.current
            var chartPeriods: [ChartPeriod] = []

            // Generate weekly periods for the last 104 weeks (2 years)
            for weekOffset in 0 ..< 104 {
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                      let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)
                else {
                    continue
                }

                let fromTimestamp = String(Int(weekStart.timeIntervalSince1970))
                let toTimestamp = String(Int(weekEnd.timeIntervalSince1970))

                chartPeriods.append(ChartPeriod(from: fromTimestamp, to: toTimestamp))
            }

            let mockResponse = UserWeeklyChartListResponse(
                weeklychartlist: WeeklyChartList(
                    chart: chartPeriods,
                    attr: WeeklyChartListAttributes(user: "testuser")
                )
            )
            return mockResponse as! T

        case .userWeeklyAlbumChart:
            // Generate realistic timestamps for current week
            let now = Date()
            let calendar = Calendar.current

            // Get the start of this week, fallback to start of today if week calculation fails
            let weekStart: Date = if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) {
                weekInterval.start
            } else {
                calendar.startOfDay(for: now)
            }

            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

            let fromTimestamp = String(Int(weekStart.timeIntervalSince1970))
            let toTimestamp = String(Int(weekEnd.timeIntervalSince1970))

            // Generate multiple mock albums for better preview experience
            let mockAlbums = [
                LastFMAlbumEntry(
                    artist: LastFMAlbumEntry.LastFMArtist(
                        mbid: nil,
                        name: "Radiohead",
                        url: nil
                    ),
                    mbid: nil,
                    name: "OK Computer",
                    playcount: "25",
                    url: "https://example.com/album1",
                    attr: LastFMAlbumEntry.LastFMAlbumAttr(rank: "1")
                ),
                LastFMAlbumEntry(
                    artist: LastFMAlbumEntry.LastFMArtist(
                        mbid: nil,
                        name: "The Beatles",
                        url: nil
                    ),
                    mbid: nil,
                    name: "Abbey Road",
                    playcount: "18",
                    url: "https://example.com/album2",
                    attr: LastFMAlbumEntry.LastFMAlbumAttr(rank: "2")
                ),
                LastFMAlbumEntry(
                    artist: LastFMAlbumEntry.LastFMArtist(
                        mbid: nil,
                        name: "Pink Floyd",
                        url: nil
                    ),
                    mbid: nil,
                    name: "The Dark Side of the Moon",
                    playcount: "15",
                    url: "https://example.com/album3",
                    attr: LastFMAlbumEntry.LastFMAlbumAttr(rank: "3")
                ),
                LastFMAlbumEntry(
                    artist: LastFMAlbumEntry.LastFMArtist(
                        mbid: nil,
                        name: "Led Zeppelin",
                        url: nil
                    ),
                    mbid: nil,
                    name: "Led Zeppelin IV",
                    playcount: "12",
                    url: "https://example.com/album4",
                    attr: LastFMAlbumEntry.LastFMAlbumAttr(rank: "4")
                ),
                LastFMAlbumEntry(
                    artist: LastFMAlbumEntry.LastFMArtist(
                        mbid: nil,
                        name: "Nirvana",
                        url: nil
                    ),
                    mbid: nil,
                    name: "Nevermind",
                    playcount: "8",
                    url: "https://example.com/album5",
                    attr: LastFMAlbumEntry.LastFMAlbumAttr(rank: "5")
                ),
            ]

            let mockResponse = UserWeeklyAlbumChartResponse(
                weeklyalbumchart: WeeklyAlbumChart(
                    album: mockAlbums,
                    attr: WeeklyAlbumChartAttributes(
                        user: "testuser",
                        from: fromTimestamp,
                        to: toTimestamp
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

    static let testValue: CacheManager = // For tests, use a regular CacheManager that writes to temporary directory
        // Tests should clean up after themselves if needed
        .init()

    static let previewValue: CacheManager = // For previews, use a regular CacheManager
        // It will use temporary directory which is fine for previews
        .init()
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
