import Dependencies
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

    func testInitialState() async {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        loader = withDependencies {
            $0.lastFMClient = mockClient
        } operation: {
            WeeklyAlbumLoader()
        }
        guard case .initialized = loader.albumsState else {
            XCTFail("Expected albums state to be initialized")
            return
        }
        XCTAssertNil(loader.currentWeekInfo)
        XCTAssertNil(loader.availableYearRange)
    }

    func testYearCalculation() async {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        let testDate = Date()
        let testCalendar = Calendar.current
        let currentYear = testCalendar.component(.year, from: testDate)

        loader = withDependencies {
            $0.lastFMClient = mockClient
            $0.date = .constant(testDate)
            $0.calendar = testCalendar
        } operation: {
            WeeklyAlbumLoader()
        }

        XCTAssertEqual(loader.getYear(for: 0), currentYear)
        XCTAssertEqual(loader.getYear(for: 1), currentYear - 1)
        XCTAssertEqual(loader.getYear(for: 2), currentYear - 2)
    }

    func testCanNavigateWithNoData() async {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        loader = withDependencies {
            $0.lastFMClient = mockClient
        } operation: {
            WeeklyAlbumLoader()
        }
        XCTAssertFalse(loader.canNavigate(to: 1))
        XCTAssertFalse(loader.canNavigate(to: 0))
        XCTAssertFalse(loader.canNavigate(to: -1))
    }

    func testClearFunctionality() async {
        // Setup
        mockClient = MockWeeklyAlbumClient()
        loader = withDependencies {
            $0.lastFMClient = mockClient
        } operation: {
            WeeklyAlbumLoader()
        }
        // Set some test data
        loader.albumsState = .loaded([
            Album(name: "Test Album", artist: "Test Artist", playCount: 10),
        ])
        loader.currentWeekInfo = WeekInfo(
            weekNumber: 25,
            year: 2024,
            username: "testuser"
        )

        // Clear and verify
        loader.clear()

        guard case .initialized = loader.albumsState else {
            XCTFail("Expected albums state to be initialized")
            return
        }
        XCTAssertNil(loader.currentWeekInfo)
    }
}

// MARK: - Mock Client for Weekly Album Loader

// Use the shared TestLastFMClient instead of local MockWeeklyAlbumClient
typealias MockWeeklyAlbumClient = TestLastFMClient
