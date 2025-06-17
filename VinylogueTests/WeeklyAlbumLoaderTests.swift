import Foundation
@testable import Vinylogue
import XCTest

@MainActor
final class WeeklyAlbumLoaderTests: XCTestCase {
    nonisolated var loader: WeeklyAlbumLoader!
    nonisolated var mockClient: MockWeeklyAlbumClient!

    override func setUpWithError() throws {
        // Set up will be done in the test methods since we need MainActor
    }

    override func tearDownWithError() throws {
        loader = nil
        mockClient = nil
    }

    func testInitialState() {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        loader = WeeklyAlbumLoader(lastFMClient: mockClient)
        XCTAssertTrue(loader.albums.isEmpty)
        XCTAssertFalse(loader.isLoading)
        XCTAssertNil(loader.error)
        XCTAssertNil(loader.currentWeekInfo)
        XCTAssertNil(loader.availableYearRange)
    }

    func testYearCalculation() {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        loader = WeeklyAlbumLoader(lastFMClient: mockClient)
        let currentYear = Calendar.current.component(.year, from: Date())

        XCTAssertEqual(loader.getYear(for: 0), currentYear)
        XCTAssertEqual(loader.getYear(for: 1), currentYear - 1)
        XCTAssertEqual(loader.getYear(for: 2), currentYear - 2)
    }

    func testCanNavigateWithNoData() {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        loader = WeeklyAlbumLoader(lastFMClient: mockClient)
        XCTAssertFalse(loader.canNavigate(to: 1))
        XCTAssertFalse(loader.canNavigate(to: 0))
        XCTAssertFalse(loader.canNavigate(to: -1))
    }

    func testClearFunctionality() {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        loader = WeeklyAlbumLoader(lastFMClient: mockClient)
        // Set some test data
        loader.albums = [
            Album(name: "Test Album", artist: "Test Artist", playCount: 10),
        ]
        loader.error = .networkUnavailable
        loader.currentWeekInfo = WeeklyAlbumLoader.WeekInfo(
            weekNumber: 25,
            year: 2024,
            username: "testuser"
        )

        // Clear and verify
        loader.clear()

        XCTAssertTrue(loader.albums.isEmpty)
        XCTAssertNil(loader.error)
        XCTAssertNil(loader.currentWeekInfo)
        XCTAssertFalse(loader.isLoading)
    }
}

// MARK: - Mock Client for Weekly Album Loader

final class MockWeeklyAlbumClient: LastFMClientProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _shouldReturnError = false
    private var _mockCharts: [ChartPeriod] = []
    private var _mockAlbums: [LastFMAlbumEntry] = []

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

    func request<T: Codable>(_ endpoint: LastFMEndpoint) async throws -> T {
        if shouldReturnError {
            throw LastFMError.networkUnavailable
        }

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
