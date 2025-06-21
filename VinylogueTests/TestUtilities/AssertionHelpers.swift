@testable import Vinylogue
import XCTest

// MARK: - User Assertion Helpers

extension XCTestCase {
    /// Asserts that two User objects are equal
    func assertUsersEqual(
        _ actual: User?,
        _ expected: User?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let actual else {
            XCTFail("Actual user is nil", file: file, line: line)
            return
        }

        guard let expected else {
            XCTFail("Expected user is nil", file: file, line: line)
            return
        }

        XCTAssertEqual(actual.username, expected.username, "Username mismatch", file: file, line: line)
        XCTAssertEqual(actual.realName, expected.realName, "Real name mismatch", file: file, line: line)
        XCTAssertEqual(actual.imageURL, expected.imageURL, "Image URL mismatch", file: file, line: line)
        XCTAssertEqual(actual.url, expected.url, "URL mismatch", file: file, line: line)
        XCTAssertEqual(actual.playCount, expected.playCount, "Play count mismatch", file: file, line: line)
    }

    /// Asserts that a User has expected properties
    func assertUser(
        _ user: User?,
        hasUsername username: String,
        realName: String? = nil,
        playCount: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let user else {
            XCTFail("User is nil", file: file, line: line)
            return
        }

        XCTAssertEqual(user.username, username, "Username mismatch", file: file, line: line)

        if let realName {
            XCTAssertEqual(user.realName, realName, "Real name mismatch", file: file, line: line)
        }

        if let playCount {
            XCTAssertEqual(user.playCount, playCount, "Play count mismatch", file: file, line: line)
        }
    }
}

// MARK: - Album Assertion Helpers

extension XCTestCase {
    /// Asserts that two UserChartAlbum objects are equal
    func assertUserChartAlbumsEqual(
        _ actual: UserChartAlbum?,
        _ expected: UserChartAlbum?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let actual else {
            XCTFail("Actual album is nil", file: file, line: line)
            return
        }

        guard let expected else {
            XCTFail("Expected album is nil", file: file, line: line)
            return
        }

        XCTAssertEqual(actual.username, expected.username, "Username mismatch", file: file, line: line)
        XCTAssertEqual(actual.weekNumber, expected.weekNumber, "Week number mismatch", file: file, line: line)
        XCTAssertEqual(actual.year, expected.year, "Year mismatch", file: file, line: line)
        XCTAssertEqual(actual.name, expected.name, "Album name mismatch", file: file, line: line)
        XCTAssertEqual(actual.artist, expected.artist, "Artist name mismatch", file: file, line: line)
        XCTAssertEqual(actual.playCount, expected.playCount, "Play count mismatch", file: file, line: line)
        XCTAssertEqual(actual.rank, expected.rank, "Rank mismatch", file: file, line: line)
        XCTAssertEqual(actual.url, expected.url, "URL mismatch", file: file, line: line)
        XCTAssertEqual(actual.mbid, expected.mbid, "MBID mismatch", file: file, line: line)
        
        // Compare detail if present
        if let actualDetail = actual.detail, let expectedDetail = expected.detail {
            assertAlbumDetailsEqual(actualDetail, expectedDetail, file: file, line: line)
        } else {
            XCTAssertEqual(actual.detail != nil, expected.detail != nil, "Detail presence mismatch", file: file, line: line)
        }
    }

    /// Asserts that two AlbumDetail objects are equal
    func assertAlbumDetailsEqual(
        _ actual: UserChartAlbum.Detail,
        _ expected: UserChartAlbum.Detail,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.imageURL, expected.imageURL, "Image URL mismatch", file: file, line: line)
        XCTAssertEqual(actual.description, expected.description, "Description mismatch", file: file, line: line)
        XCTAssertEqual(actual.totalPlayCount, expected.totalPlayCount, "Total play count mismatch", file: file, line: line)
        XCTAssertEqual(actual.userPlayCount, expected.userPlayCount, "User play count mismatch", file: file, line: line)
    }
    
    /// Asserts that a UserChartAlbum has expected properties
    func assertUserChartAlbum(
        _ album: UserChartAlbum?,
        hasUsername username: String,
        weekNumber: Int,
        year: Int,
        name: String,
        artist: String,
        playCount: Int? = nil,
        rank: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let album else {
            XCTFail("Album is nil", file: file, line: line)
            return
        }

        XCTAssertEqual(album.name, name, "Album name mismatch", file: file, line: line)
        XCTAssertEqual(album.artist, artist, "Artist name mismatch", file: file, line: line)

        if let playCount {
            XCTAssertEqual(album.playCount, playCount, "Play count mismatch", file: file, line: line)
        }

        if let rank {
            XCTAssertEqual(album.rank, rank, "Rank mismatch", file: file, line: line)
        }
    }
}

// MARK: - Collection Assertion Helpers

extension XCTestCase {
    /// Asserts that an array of users contains expected usernames
    func assertUsers(
        _ users: [User],
        containUsernames usernames: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actualUsernames = users.map(\.username)

        for username in usernames {
            XCTAssertTrue(
                actualUsernames.contains(username),
                "Expected username '\(username)' not found in users: \(actualUsernames)",
                file: file,
                line: line
            )
        }
    }

    /// Asserts that an array of albums contains expected album names
    func assertAlbums(
        _ albums: [UserChartAlbum],
        containAlbumNames names: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actualNames = albums.map(\.name)

        for name in names {
            XCTAssertTrue(
                actualNames.contains(name),
                "Expected album name '\(name)' not found in albums: \(actualNames)",
                file: file,
                line: line
            )
        }
    }

    /// Asserts that UserChartAlbums are sorted by rank in ascending order
    func assertUserChartAlbumsSortedByRank(
        _ albums: [UserChartAlbum],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let rankedAlbums = albums.compactMap(\.rank)
        let sortedRanks = rankedAlbums.sorted()

        XCTAssertEqual(
            rankedAlbums,
            sortedRanks,
            "Albums are not sorted by rank. Expected: \(sortedRanks), Actual: \(rankedAlbums)",
            file: file,
            line: line
        )
    }
}

// MARK: - Chart Period Assertion Helpers

extension XCTestCase {
    /// Asserts that two ChartPeriod objects are equal
    func assertChartPeriodsEqual(
        _ actual: ChartPeriod?,
        _ expected: ChartPeriod?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let actual else {
            XCTFail("Actual chart period is nil", file: file, line: line)
            return
        }

        guard let expected else {
            XCTFail("Expected chart period is nil", file: file, line: line)
            return
        }

        XCTAssertEqual(actual.from, expected.from, "From timestamp mismatch", file: file, line: line)
        XCTAssertEqual(actual.to, expected.to, "To timestamp mismatch", file: file, line: line)
        XCTAssertEqual(actual.fromDate.timeIntervalSince1970, expected.fromDate.timeIntervalSince1970, accuracy: 1.0, "From date mismatch", file: file, line: line)
        XCTAssertEqual(actual.toDate.timeIntervalSince1970, expected.toDate.timeIntervalSince1970, accuracy: 1.0, "To date mismatch", file: file, line: line)
    }
}

// MARK: - Error Assertion Helpers

extension XCTestCase {
    /// Helper to assert that an async throwing function throws a specific error
    func assertThrowsError<E: Error & Equatable>(
        _ expression: @autoclosure () async throws -> some Any,
        expectedError: E,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error \(expectedError) but no error was thrown", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expectedError, "Wrong error thrown", file: file, line: line)
        } catch {
            XCTFail("Expected error \(expectedError) but got \(error)", file: file, line: line)
        }
    }

    /// Helper to assert that an async throwing function throws a LastFMError
    func assertThrowsLastFMError(
        _ expression: @autoclosure () async throws -> some Any,
        expectedError: LastFMError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected LastFMError \(expectedError) but no error was thrown", file: file, line: line)
        } catch let error as LastFMError {
            // Note: LastFMError comparison needs to be done case by case since it's not Equatable
            switch (error, expectedError) {
            case (.networkUnavailable, .networkUnavailable),
                 (.invalidAPIKey, .invalidAPIKey),
                 (.invalidResponse, .invalidResponse),
                 (.serviceUnavailable, .serviceUnavailable),
                 (.userNotFound, .userNotFound):
                break // Success - errors match
            case let (.apiError(code1, message1), .apiError(code2, message2)):
                XCTAssertEqual(code1, code2, "API error codes don't match", file: file, line: line)
                XCTAssertEqual(message1, message2, "API error messages don't match", file: file, line: line)
            case let (.decodingError(error1), .decodingError(error2)):
                XCTAssertEqual(error1.localizedDescription, error2.localizedDescription, "Decoding errors don't match", file: file, line: line)
            default:
                XCTFail("Expected LastFMError \(expectedError) but got \(error)", file: file, line: line)
            }
        } catch {
            XCTFail("Expected LastFMError \(expectedError) but got \(error)", file: file, line: line)
        }
    }
}
