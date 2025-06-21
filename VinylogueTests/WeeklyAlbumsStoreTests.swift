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
            Album(name: "Test Album", artist: "Test Artist", playCount: 10),
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
}

// MARK: - Mock Client for Weekly Album Loader

// Use the shared TestLastFMClient instead of local MockWeeklyAlbumClient
typealias MockWeeklyAlbumClient = TestLastFMClient
