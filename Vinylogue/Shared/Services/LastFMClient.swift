import Dependencies
import Foundation
import Network

// MARK: - Protocol

protocol LastFMClientProtocol: Sendable {
    func request<T: Codable>(_ endpoint: LastFMEndpoint) async throws -> T
    func fetchAlbumInfo(artist: String?, album: String?, mbid: String?, username: String?) async throws -> Album
}

struct LastFMClient: LastFMClientProtocol, Sendable {
    private let baseURL = URL(string: "https://ws.audioscrobbler.com/2.0/")!
    private let apiKey = Secrets.apiKey
    private let session = URLSession.shared
    private let networkMonitor = NWPathMonitor()
    @Dependency(\.cacheManager) private var cacheManager

    init() {
        setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        networkMonitor.start(queue: DispatchQueue.global())
    }

    private var isNetworkAvailable: Bool {
        networkMonitor.currentPath.status == .satisfied
    }

    func request<T: Codable>(_ endpoint: LastFMEndpoint) async throws -> T {
        guard isNetworkAvailable else {
            throw LastFMError.networkUnavailable
        }

        guard !apiKey.isEmpty, apiKey != "YOUR_LASTFM_API_KEY_HERE" else {
            throw LastFMError.invalidAPIKey
        }

        let url = buildURL(for: endpoint)

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LastFMError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200 ... 299:
                break
            case 400 ... 499:
                if let errorResponse = try? JSONDecoder().decode(LastFMErrorResponse.self, from: data) {
                    throw mapLastFMError(code: errorResponse.error, message: errorResponse.message)
                }
                throw LastFMError.invalidResponse
            case 500 ... 599:
                throw LastFMError.serviceUnavailable
            default:
                throw LastFMError.invalidResponse
            }

            if let errorResponse = try? JSONDecoder().decode(LastFMErrorResponse.self, from: data) {
                throw mapLastFMError(code: errorResponse.error, message: errorResponse.message)
            }

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw LastFMError.decodingError(error.toEquatableError())
            }

        } catch let error as LastFMError {
            throw error
        } catch {
            throw LastFMError.networkUnavailable
        }
    }

    func mapLastFMError(code: Int, message: String) -> LastFMError {
        switch code {
        case 6:
            .userNotFound
        case 10:
            .invalidAPIKey
        case 11, 16:
            .serviceUnavailable
        default:
            .apiError(code: code, message: message)
        }
    }

    func requestData(_ endpoint: LastFMEndpoint) async throws -> Data {
        // Check network availability
        guard isNetworkAvailable else {
            throw LastFMError.networkUnavailable
        }

        // Validate API key
        guard !apiKey.isEmpty, apiKey != "YOUR_LASTFM_API_KEY_HERE" else {
            throw LastFMError.invalidAPIKey
        }

        let url = buildURL(for: endpoint)

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LastFMError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200 ... 299:
                return data
            case 400 ... 499:
                if let errorResponse = try? JSONDecoder().decode(LastFMErrorResponse.self, from: data) {
                    throw mapLastFMError(code: errorResponse.error, message: errorResponse.message)
                }
                throw LastFMError.invalidResponse
            case 500 ... 599:
                throw LastFMError.serviceUnavailable
            default:
                throw LastFMError.invalidResponse
            }

        } catch let error as LastFMError {
            throw error
        } catch {
            throw LastFMError.networkUnavailable
        }
    }

    func buildURL(for endpoint: LastFMEndpoint) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!

        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
        ]

        queryItems.append(contentsOf: endpoint.queryItems)
        components.queryItems = queryItems

        return components.url!
    }
}

// MARK: - Convenience Methods

extension LastFMClient {
    /// Fetch user's weekly chart periods
    func fetchWeeklyChartList(for username: String) async throws -> [WeeklyChart] {
        let response: UserWeeklyChartListResponse = try await request(.userWeeklyChartList(username: username))

        return (response.weeklychartlist.chart ?? []).map { period in
            WeeklyChart(
                from: period.fromDate,
                to: period.toDate,
                albums: []
            )
        }
    }

    /// Fetch weekly album chart for specific period
    func fetchWeeklyAlbumChart(for username: String, from: Date, to: Date) async throws -> [Album] {
        let response: UserWeeklyAlbumChartResponse = try await request(.userWeeklyAlbumChart(username: username, from: from, to: to))

        return (response.weeklyalbumchart.album ?? []).map { entry in
            Album(
                name: entry.name,
                artist: entry.artist.name,
                imageURL: nil, // Will be loaded separately via album.getinfo
                playCount: entry.playCount,
                rank: entry.rankNumber,
                url: entry.url,
                mbid: entry.mbid
            )
        }
    }

    /// Fetch detailed album information
    func fetchAlbumInfo(artist: String? = nil, album: String? = nil, mbid: String? = nil, username: String? = nil) async throws -> Album {
        // Create cache key based on album identifiers
        let cacheKey: String
        if let mbid, !mbid.isEmpty {
            cacheKey = "album_info_mbid_\(mbid)_\(username ?? "none")"
        } else if let artist, let album {
            let normalizedArtist = artist.lowercased().replacingOccurrences(of: " ", with: "_")
            let normalizedAlbum = album.lowercased().replacingOccurrences(of: " ", with: "_")
            cacheKey = "album_info_\(normalizedArtist)_\(normalizedAlbum)_\(username ?? "none")"
        } else {
            // Fallback to original API call without caching for invalid parameters
            let response: AlbumInfoResponse = try await request(.albumInfo(artist: artist, album: album, mbid: mbid, username: username))
            return createAlbumFromResponse(response.album)
        }

        // Try to load from cache first
        if let cachedAlbum: Album = try? await cacheManager.retrieve(Album.self, key: cacheKey) {
            return cachedAlbum
        }

        // Fetch from API and cache the result
        let response: AlbumInfoResponse = try await request(.albumInfo(artist: artist, album: album, mbid: mbid, username: username))
        let album = createAlbumFromResponse(response.album)

        // Cache the album info
        try await cacheManager.store(album, key: cacheKey)

        return album
    }

    private func createAlbumFromResponse(_ info: LastFMAlbumInfo) -> Album {
        var album = Album(
            name: info.name,
            artist: info.artist,
            imageURL: info.imageURL,
            playCount: 0, // This will be set from weekly chart data
            rank: nil,
            url: info.url,
            mbid: info.mbid
        )

        album.description = info.description
        album.totalPlayCount = info.totalPlayCount
        album.userPlayCount = info.userPlayCount
        album.isDetailLoaded = true

        return album
    }

    /// Fetch user information
    func fetchUserInfo(for username: String) async throws -> User {
        let response: UserInfoResponse = try await request(.userInfo(username: username))
        let info = response.user

        return User(
            username: info.name,
            realName: info.realname,
            imageURL: info.imageURL,
            url: info.url,
            playCount: info.totalPlayCount
        )
    }

    /// Fetch user's friends
    func fetchUserFriends(for username: String, limit: Int = 500) async throws -> [User] {
        let response: UserFriendsResponse = try await request(.userFriends(username: username, limit: limit))

        return response.friends.user.map { friend in
            User(
                username: friend.name,
                realName: friend.realname,
                imageURL: friend.imageURL,
                url: friend.url,
                playCount: friend.totalPlayCount
            )
        }
    }
}

// MARK: - Endpoints

enum LastFMEndpoint {
    case userWeeklyChartList(username: String)
    case userWeeklyAlbumChart(username: String, from: Date, to: Date)
    case albumInfo(artist: String?, album: String?, mbid: String?, username: String?)
    case userInfo(username: String)
    case userFriends(username: String, limit: Int = 500)

    var queryItems: [URLQueryItem] {
        switch self {
        case let .userWeeklyChartList(username):
            return [
                URLQueryItem(name: "method", value: "user.getweeklychartlist"),
                URLQueryItem(name: "user", value: username),
            ]

        case let .userWeeklyAlbumChart(username, from, to):
            return [
                URLQueryItem(name: "method", value: "user.getweeklyalbumchart"),
                URLQueryItem(name: "user", value: username),
                URLQueryItem(name: "from", value: String(Int(from.timeIntervalSince1970))),
                URLQueryItem(name: "to", value: String(Int(to.timeIntervalSince1970))),
            ]

        case let .albumInfo(artist, album, mbid, username):
            var items = [URLQueryItem(name: "method", value: "album.getinfo")]

            if let mbid, !mbid.isEmpty {
                items.append(URLQueryItem(name: "mbid", value: mbid))
            } else if let artist, let album {
                items.append(URLQueryItem(name: "artist", value: artist))
                items.append(URLQueryItem(name: "album", value: album))
            }

            if let username {
                items.append(URLQueryItem(name: "username", value: username))
            }

            return items

        case let .userInfo(username):
            return [
                URLQueryItem(name: "method", value: "user.getinfo"),
                URLQueryItem(name: "user", value: username),
            ]

        case let .userFriends(username, limit):
            return [
                URLQueryItem(name: "method", value: "user.getfriends"),
                URLQueryItem(name: "user", value: username),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        }
    }
}

// MARK: - Error Types

enum LastFMError: Error, LocalizedError, Equatable {
    case invalidAPIKey
    case userNotFound
    case networkUnavailable
    case invalidResponse
    case serviceUnavailable
    case decodingError(EquatableError)
    case apiError(code: Int, message: String)
    case noDataAvailable

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            "Invalid API configuration"
        case .userNotFound:
            "User not found. Please check the username."
        case .networkUnavailable:
            "Network unavailable. Showing cached data."
        case .invalidResponse:
            "Unable to load data. Please try again."
        case .serviceUnavailable:
            "Last.fm service is temporarily unavailable"
        case let .decodingError(error):
            "Data parsing error: \(error.localizedDescription)"
        case let .apiError(code, message):
            "API Error \(code): \(message)"
        case .noDataAvailable:
            "No chart data available for this time period."
        }
    }
}

// MARK: - Response Types

struct LastFMErrorResponse: Codable, Sendable {
    let error: Int
    let message: String
}
