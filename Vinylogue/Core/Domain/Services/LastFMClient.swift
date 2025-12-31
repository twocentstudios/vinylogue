import Dependencies
import Foundation

// MARK: - Protocol

protocol LastFMClientProtocol: Sendable {
    func request<T: Codable>(_ endpoint: LastFMEndpoint) async throws -> T
    func fetchAlbumInfo(artist: String?, album: String?, mbid: String?, username: String?) async throws -> AlbumDetail
}

struct LastFMClient: LastFMClientProtocol, Sendable {
    private let baseURL = URL(string: "https://ws.audioscrobbler.com/2.0/")!
    private let apiKey = Secrets.apiKey
    private let session = URLSession.shared
    @Dependency(\.cacheManager) private var cacheManager

    func request<T: Codable>(_ endpoint: LastFMEndpoint) async throws -> T {
        try validatePrerequisites()
        let url = buildURL(for: endpoint)

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LastFMError.invalidResponse
            }

            try handleHTTPResponse(httpResponse, data: data)

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
        } catch let error as CancellationError {
            throw error
        } catch {
            throw mapTransportError(error)
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

    private func validatePrerequisites() throws {
        guard !apiKey.isEmpty, apiKey != "YOUR_LASTFM_API_KEY_HERE" else {
            throw LastFMError.invalidAPIKey
        }
    }

    private func handleHTTPResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
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
    }

    private func handleHTTPErrorResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
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
    }

    func requestData(_ endpoint: LastFMEndpoint) async throws -> Data {
        try validatePrerequisites()
        let url = buildURL(for: endpoint)

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LastFMError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200 ... 299:
                return data
            default:
                try handleHTTPErrorResponse(httpResponse, data: data)
                return data // This line will never be reached, but satisfies the compiler
            }

        } catch let error as LastFMError {
            throw error
        } catch let error as CancellationError {
            throw error
        } catch {
            throw mapTransportError(error)
        }
    }

    func buildURL(for endpoint: LastFMEndpoint) -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            fatalError("Invalid base URL configuration")
        }

        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
        ]

        queryItems.append(contentsOf: endpoint.queryItems)
        components.queryItems = queryItems

        guard let url = components.url else {
            fatalError("Failed to construct URL for endpoint: \(endpoint)")
        }
        return url
    }

    private func mapTransportError(_ error: Error) -> LastFMError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .timedOut,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed,
                 .internationalRoamingOff,
                 .dataNotAllowed:
                return .networkUnavailable
            default:
                return .invalidResponse
            }
        }

        return .invalidResponse
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

    /// Fetch weekly album chart for specific period - NOTE: This is deprecated, use WeeklyAlbumsStore instead
    func fetchWeeklyAlbumChart(for username: String, from: Date, to: Date) async throws -> [LastFMAlbumEntry] {
        let response: UserWeeklyAlbumChartResponse = try await request(.userWeeklyAlbumChart(username: username, from: from, to: to))
        return response.weeklyalbumchart.album ?? []
    }

    /// Fetch detailed album information
    func fetchAlbumInfo(artist: String? = nil, album: String? = nil, mbid: String? = nil, username: String? = nil) async throws -> AlbumDetail {
        // Create cache key based on album identifiers
        guard let cacheKey = CacheKeyBuilder.albumInfo(artist: artist, album: album, mbid: mbid, username: username) else {
            // Fallback to original API call without caching for invalid parameters
            let response: AlbumInfoResponse = try await request(.albumInfo(artist: artist, album: album, mbid: mbid, username: username))
            return createAlbumDetailFromResponse(response.album)
        }

        // Try to load from cache first
        do {
            if let cachedAlbum: AlbumDetail = try await cacheManager.retrieve(AlbumDetail.self, key: cacheKey) {
                return cachedAlbum
            }
        } catch {
            print("Cache retrieval failed for album info \(cacheKey): \(error)")
            // Continue to fetch from API
        }

        // Fetch from API and cache the result
        let response: AlbumInfoResponse = try await request(.albumInfo(artist: artist, album: album, mbid: mbid, username: username))
        let albumDetail = createAlbumDetailFromResponse(response.album)

        // Cache the album info
        try await cacheManager.store(albumDetail, key: cacheKey)

        return albumDetail
    }

    private func createAlbumDetailFromResponse(_ info: LastFMAlbumInfo) -> AlbumDetail {
        AlbumDetail(
            name: info.name,
            artist: info.artist,
            url: info.url,
            mbid: info.mbid,
            imageURL: info.imageURL,
            description: cleanupDescription(info.description),
            totalPlayCount: info.totalPlayCount,
            userPlayCount: info.userPlayCount
        )
    }

    /// Clean up album description by removing Last.fm "Read more" links and Creative Commons text
    func cleanupDescription(_ description: String?) -> String? {
        guard let description else { return nil }

        var cleanedDescription = description

        // Remove the "Read more on Last.fm" link pattern
        let lastFmPattern = #"<a href="[^"]*">Read more on Last\.fm</a>\.?"#
        cleanedDescription = cleanedDescription.replacingOccurrences(
            of: lastFmPattern,
            with: "",
            options: .regularExpression
        )

        // Remove Creative Commons text
        let creativeCommonsPattern = "User-contributed text is available under the Creative Commons By-SA License; additional terms may apply."
        cleanedDescription = cleanedDescription.replacingOccurrences(of: creativeCommonsPattern, with: "")

        cleanedDescription = cleanedDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleanedDescription.isEmpty ? nil : cleanedDescription
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
