@testable import Vinylogue
import XCTest

final class TestLastFMClient: LastFMClientProtocol, @unchecked Sendable {
    private let lock = NSLock()

    // Generic mock response system
    private var _mockResponses: [String: Any] = [:]
    private var _mockError: Error?
    private var _shouldReturnError = false

    // Specific mock data for different test scenarios
    private var _mockCharts: [ChartPeriod] = []
    private var _mockAlbums: [LastFMAlbumEntry] = []

    // Thread-safe accessors for generic responses
    var mockResponses: [String: Any] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _mockResponses
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _mockResponses = newValue
        }
    }

    var mockError: Error? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _mockError
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _mockError = newValue
        }
    }

    var shouldReturnError: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _shouldReturnError
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _shouldReturnError = newValue
        }
    }

    // Thread-safe accessors for specific mock data
    var mockCharts: [ChartPeriod] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _mockCharts
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _mockCharts = newValue
        }
    }

    var mockAlbums: [LastFMAlbumEntry] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _mockAlbums
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _mockAlbums = newValue
        }
    }

    // Convenience methods for setting up common responses
    func setMockResponse(_ response: some Codable, forEndpoint endpoint: LastFMEndpoint) {
        let key = endpointKey(endpoint)
        lock.lock()
        defer { lock.unlock() }
        _mockResponses[key] = response
    }

    func setGenericMockResponse(_ response: some Codable) {
        lock.lock()
        defer { lock.unlock() }
        _mockResponses["generic"] = response
    }

    // Reset method for clean test setup
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _mockResponses.removeAll()
        _mockError = nil
        _shouldReturnError = false
        _mockCharts.removeAll()
        _mockAlbums.removeAll()
    }

    func request<T: Codable>(_ endpoint: LastFMEndpoint) async throws -> T {
        // Check for error conditions first
        if shouldReturnError {
            throw LastFMError.networkUnavailable
        }

        if let error = mockError {
            throw error
        }

        // Try to find specific response for this endpoint
        let key = endpointKey(endpoint)
        if let specificResponse = mockResponses[key] as? T {
            return specificResponse
        }

        // Handle structured endpoint responses
        switch endpoint {
        case .userWeeklyChartList:
            let response = UserWeeklyChartListResponse(
                weeklychartlist: WeeklyChartList(
                    chart: mockCharts,
                    attr: WeeklyChartListAttributes(user: "testuser")
                )
            )
            return response as! T

        case .userWeeklyAlbumChart:
            let response = UserWeeklyAlbumChartResponse(
                weeklyalbumchart: WeeklyAlbumChart(
                    album: mockAlbums,
                    attr: WeeklyAlbumChartAttributes(user: "testuser", from: "1", to: "2")
                )
            )
            return response as! T

        default:
            // Try generic response
            if let genericResponse = mockResponses["generic"] as? T {
                return genericResponse
            }

            throw LastFMError.invalidResponse
        }
    }

    func fetchAlbumInfo(artist: String?, album: String?, mbid: String?, username: String?) async throws -> Album {
        // Check for error conditions first
        if shouldReturnError {
            throw LastFMError.networkUnavailable
        }

        if let error = mockError {
            throw error
        }

        // Return mock album with provided or default values
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

    // Helper method to generate consistent keys for endpoints
    private func endpointKey(_ endpoint: LastFMEndpoint) -> String {
        switch endpoint {
        case let .userWeeklyChartList(user):
            "userWeeklyChartList_\(user)"
        case let .userWeeklyAlbumChart(user, from, to):
            "userWeeklyAlbumChart_\(user)_\(from)_\(to)"
        case let .userFriends(user, _):
            "userFriends_\(user)"
        case let .userInfo(user):
            "userInfo_\(user)"
        case let .albumInfo(artist, album, mbid, username):
            "albumInfo_\(artist ?? "")_\(album ?? "")_\(mbid ?? "")_\(username ?? "")"
        }
    }
}
