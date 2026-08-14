import CustomDump
import Dependencies
import Foundation
@testable import Vinylogue
import XCTest

@MainActor
final class WeeklyAlbumsStoreTests: XCTestCase {
    nonisolated var store: WeeklyAlbumsStore!
    nonisolated var mockClient: MockWeeklyAlbumClient!
    nonisolated let testUser = User(username: "testuser")

    override func setUpWithError() throws {
        // Set up will be done in the test methods since we need MainActor
    }

    override func tearDownWithError() throws {
        store = nil
        mockClient = nil
    }

    func testInitialState() async {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        store = withDependencies {
            $0.lastFMClient = mockClient
        } operation: {
            WeeklyAlbumsStore(user: testUser)
        }
        guard case .initialized = store.albumsState else {
            XCTFail("Expected albums state to be initialized")
            return
        }
        XCTAssertNil(store.currentWeekInfo)
        XCTAssertNil(store.availableYearRange)
    }

    func testYearCalculation() async {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        let testDate = Date()
        let testCalendar = Calendar.current
        let currentYear = testCalendar.component(.year, from: testDate)

        store = withDependencies {
            $0.lastFMClient = mockClient
            $0.date = .constant(testDate)
            $0.calendar = testCalendar
        } operation: {
            WeeklyAlbumsStore(user: testUser)
        }

        XCTAssertEqual(store.getYear(for: 0), currentYear)
        XCTAssertEqual(store.getYear(for: 1), currentYear - 1)
        XCTAssertEqual(store.getYear(for: 2), currentYear - 2)
    }

    func testCanNavigateWithNoData() async {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        store = withDependencies {
            $0.lastFMClient = mockClient
        } operation: {
            WeeklyAlbumsStore(user: testUser)
        }
        XCTAssertFalse(store.canNavigate(to: 1))
        XCTAssertFalse(store.canNavigate(to: 0))
        XCTAssertFalse(store.canNavigate(to: -1))
    }

    func testClearFunctionality() async {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        store = withDependencies {
            $0.lastFMClient = mockClient
        } operation: {
            WeeklyAlbumsStore(user: testUser)
        }
        // Set some test data
        store.albumsState = .loaded([
            TestDataFactory.createUserChartAlbum(
                username: testUser.username,
                weekNumber: 25,
                year: 2024,
                name: "Test Album",
                artist: "Test Artist",
                playCount: 10
            ),
        ])
        store.currentWeekInfo = WeekInfo(
            weekNumber: 25,
            year: 2024,
            username: "testuser"
        )

        // Clear and verify
        store.clear()

        guard case .initialized = store.albumsState else {
            XCTFail("Expected albums state to be initialized")
            return
        }
        XCTAssertNil(store.currentWeekInfo)
    }

    func testStaleCachedChartListRevalidatesOnceAndLoadsAlbums() async throws {
        let context = try await makeLoadContext(
            cachedCharts: [staleChartPeriod],
            networkCharts: [matchingChartPeriod]
        )

        await context.store.loadAlbums()

        expectNoDifference(context.store.albumsState, .loaded([expectedAlbum]))
        expectNoDifference(context.store.playCountFilter, 0)
        expectNoDifference(context.client.weeklyChartListRequestCount, 1)
        expectNoDifference(context.client.weeklyAlbumChartRequestCount, 1)
    }

    func testFirstChartListFetchDoesNotRevalidate() async throws {
        let context = try await makeLoadContext(
            cachedCharts: nil,
            networkCharts: [matchingChartPeriod]
        )

        await context.store.loadAlbums()

        expectNoDifference(context.store.albumsState, .loaded([expectedAlbum]))
        expectNoDifference(context.store.playCountFilter, 0)
        expectNoDifference(context.client.weeklyChartListRequestCount, 1)
        expectNoDifference(context.client.weeklyAlbumChartRequestCount, 1)
    }

    func testCachedMatchingChartListDoesNotRevalidate() async throws {
        let context = try await makeLoadContext(
            cachedCharts: [matchingChartPeriod],
            networkCharts: []
        )

        await context.store.loadAlbums()

        expectNoDifference(context.store.albumsState, .loaded([expectedAlbum]))
        expectNoDifference(context.store.playCountFilter, 0)
        expectNoDifference(context.client.weeklyChartListRequestCount, 0)
        expectNoDifference(context.client.weeklyAlbumChartRequestCount, 1)
    }

    func testFreshChartListWithoutTargetDoesNotRetry() async throws {
        let context = try await makeLoadContext(
            cachedCharts: nil,
            networkCharts: [staleChartPeriod]
        )

        await context.store.loadAlbums()

        expectNoDifference(context.store.albumsState, .failed(.noDataAvailable))
        expectNoDifference(context.client.weeklyChartListRequestCount, 1)
        expectNoDifference(context.client.weeklyAlbumChartRequestCount, 0)
    }

    func testStaleCachedChartListReportsFailedRevalidationWithoutRetrying() async throws {
        let context = try await makeLoadContext(
            cachedCharts: [staleChartPeriod],
            networkCharts: []
        )
        context.client.mockError = LastFMError.networkUnavailable

        await context.store.loadAlbums()

        expectNoDifference(context.store.albumsState, .failed(.networkUnavailable))
        expectNoDifference(context.client.weeklyChartListRequestCount, 1)
        expectNoDifference(context.client.weeklyAlbumChartRequestCount, 0)
    }

    private struct LoadContext {
        let store: WeeklyAlbumsStore
        let client: MockWeeklyAlbumClient
    }

    private var now: Date {
        Date(timeIntervalSince1970: 1_786_676_400)
    }

    private var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private var matchingChartPeriod: ChartPeriod {
        TestDataFactory.createChartPeriod(
            from: Date(timeIntervalSince1970: 1_754_784_000),
            to: Date(timeIntervalSince1970: 1_755_388_799)
        )
    }

    private var staleChartPeriod: ChartPeriod {
        TestDataFactory.createChartPeriod(
            from: Date(timeIntervalSince1970: 1_749_945_600),
            to: Date(timeIntervalSince1970: 1_750_550_399)
        )
    }

    private var expectedAlbum: UserChartAlbum {
        UserChartAlbum(
            username: testUser.username,
            weekNumber: testCalendar.component(.weekOfYear, from: matchingChartPeriod.fromDate),
            year: testCalendar.component(.yearForWeekOfYear, from: matchingChartPeriod.fromDate),
            name: "Test Album",
            artist: "Test Artist",
            playCount: 10,
            rank: 1,
            url: "https://example.com/album",
            mbid: nil
        )
    }

    private func makeLoadContext(cachedCharts: [ChartPeriod]?, networkCharts: [ChartPeriod]) async throws -> LoadContext {
        let cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WeeklyAlbumsStoreTests")
            .appendingPathComponent(UUID().uuidString)
        let cacheManager = CacheManager(cacheDirectory: cacheDirectory)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: cacheDirectory)
        }

        if let cachedCharts {
            let cachedResponse = TestDataFactory.createUserWeeklyChartListResponse(
                username: testUser.username,
                charts: cachedCharts
            )
            try await cacheManager.store(
                cachedResponse,
                key: CacheKeyBuilder.weeklyChartList(username: testUser.username)
            )
        }

        let client = MockWeeklyAlbumClient()
        client.mockCharts = networkCharts
        client.mockAlbums = [TestDataFactory.createLastFMAlbumEntry()]

        let store = withDependencies {
            $0.lastFMClient = client
            $0.cacheManager = cacheManager
            $0.date = .constant(now)
            $0.calendar = testCalendar
            $0.defaultAppStorage = UserDefaults(
                suiteName: "WeeklyAlbumsStoreTests-\(UUID().uuidString)"
            )!
        } operation: {
            WeeklyAlbumsStore(user: testUser)
        }
        store.$playCountFilter.withLock { $0 = 0 }

        return LoadContext(store: store, client: client)
    }
}

// MARK: - Mock Client for Weekly Album Loader

// Use the shared TestLastFMClient instead of local MockWeeklyAlbumClient
typealias MockWeeklyAlbumClient = TestLastFMClient
