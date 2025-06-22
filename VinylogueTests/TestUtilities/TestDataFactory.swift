import Foundation
@testable import Vinylogue

enum TestDataFactory {
    // MARK: - User Creation

    static func createUser(
        username: String = "testuser",
        realName: String = "Test User",
        imageURL: String? = nil,
        url: String? = nil,
        playCount: Int? = 100
    ) -> User {
        User(
            username: username,
            realName: realName,
            imageURL: imageURL,
            url: url,
            playCount: playCount
        )
    }

    static func createFriend(
        username: String = "friend1",
        realName: String = "Friend One",
        imageURL: String? = nil,
        url: String? = nil,
        playCount: Int? = 100
    ) -> User {
        User(
            username: username,
            realName: realName,
            imageURL: imageURL,
            url: url,
            playCount: playCount
        )
    }

    static func createUsers(count: Int, usernamePrefix: String = "user") -> [User] {
        (1 ... count).map { index in
            createUser(
                username: "\(usernamePrefix)\(index)",
                realName: "Test User \(index)",
                playCount: 100 + index
            )
        }
    }

    // MARK: - UserChartAlbum Creation

    static func createUserChartAlbum(
        username: String = "testuser",
        weekNumber: Int = 1,
        year: Int = 2024,
        name: String = "Test Album",
        artist: String = "Test Artist",
        playCount: Int = 10,
        rank: Int? = 1,
        url: String? = nil,
        mbid: String? = nil,
        withDetail: Bool = false
    ) -> UserChartAlbum {
        var album = UserChartAlbum(
            username: username,
            weekNumber: weekNumber,
            year: year,
            name: name,
            artist: artist,
            playCount: playCount,
            rank: rank,
            url: url,
            mbid: mbid
        )

        if withDetail {
            album.detail = UserChartAlbum.Detail(
                imageURL: "https://example.com/test.jpg",
                description: "Test album description",
                totalPlayCount: 1000,
                userPlayCount: 50
            )
        }

        return album
    }

    static func createUserChartAlbums(count: Int, username: String = "testuser", weekNumber: Int = 1, year: Int = 2024, artistPrefix: String = "Artist") -> [UserChartAlbum] {
        (1 ... count).map { index in
            createUserChartAlbum(
                username: username,
                weekNumber: weekNumber,
                year: year,
                name: "Album \(index)",
                artist: "\(artistPrefix) \(index)",
                playCount: 10 + index,
                rank: index
            )
        }
    }

    // MARK: - Legacy Album Creation (for specific API tests)

    static func createAlbumDetail(
        name: String = "Test Album",
        artist: String = "Test Artist",
        url: String? = nil,
        mbid: String? = nil,
        imageURL: String? = nil,
        description: String? = "Test description",
        totalPlayCount: Int? = 1000,
        userPlayCount: Int? = 50
    ) -> AlbumDetail {
        AlbumDetail(
            name: name,
            artist: artist,
            url: url,
            mbid: mbid,
            imageURL: imageURL,
            description: description,
            totalPlayCount: totalPlayCount,
            userPlayCount: userPlayCount
        )
    }

    // MARK: - Chart Period Creation

    static func createChartPeriod(
        from: Date? = nil,
        to: Date? = nil
    ) -> ChartPeriod {
        let fromDate = from ?? Date().addingTimeInterval(-7 * 24 * 60 * 60) // 1 week ago
        let toDate = to ?? Date()

        return ChartPeriod(
            from: String(Int(fromDate.timeIntervalSince1970)),
            to: String(Int(toDate.timeIntervalSince1970))
        )
    }

    static func createChartPeriods(count: Int) -> [ChartPeriod] {
        let now = Date()
        return (0 ..< count).map { index in
            let weekOffset = TimeInterval(index * 7 * 24 * 60 * 60) // weeks in seconds
            let fromDate = now.addingTimeInterval(-weekOffset - 7 * 24 * 60 * 60)
            let toDate = now.addingTimeInterval(-weekOffset)

            return createChartPeriod(from: fromDate, to: toDate)
        }
    }

    // MARK: - LastFM API Response Creation

    static func createLastFMAlbumEntry(
        name: String = "Test Album",
        artist: String = "Test Artist",
        playCount: String = "10",
        rank: String = "1",
        url: String = "https://example.com/album",
        mbid: String? = nil
    ) -> LastFMAlbumEntry {
        LastFMAlbumEntry(
            artist: LastFMAlbumEntry.LastFMArtist(mbid: nil, name: artist, url: nil),
            mbid: mbid,
            name: name,
            playcount: playCount,
            url: url,
            attr: LastFMAlbumEntry.LastFMAlbumAttr(rank: rank)
        )
    }

    static func createUserWeeklyAlbumChartResponse(
        username: String = "testuser",
        albums: [LastFMAlbumEntry]? = nil,
        from: String = "1",
        to: String = "2"
    ) -> UserWeeklyAlbumChartResponse {
        let albumEntries = albums ?? [createLastFMAlbumEntry()]

        return UserWeeklyAlbumChartResponse(
            weeklyalbumchart: WeeklyAlbumChart(
                album: albumEntries,
                attr: WeeklyAlbumChartAttributes(user: username, from: from, to: to)
            )
        )
    }

    static func createUserWeeklyChartListResponse(
        username: String = "testuser",
        charts: [ChartPeriod]? = nil
    ) -> UserWeeklyChartListResponse {
        let chartPeriods = charts ?? [createChartPeriod()]

        return UserWeeklyChartListResponse(
            weeklychartlist: WeeklyChartList(
                chart: chartPeriods,
                attr: WeeklyChartListAttributes(user: username)
            )
        )
    }

    // MARK: - Legacy Model Creation

    static func createLegacyUser(
        username: String = "testuser",
        realName: String = "Test User",
        imageThumbURL: String? = nil,
        imageURL: String? = nil,
        url: String? = nil
    ) -> LegacyUser {
        LegacyUser(
            username: username,
            realName: realName,
            imageThumbURL: imageThumbURL,
            imageURL: imageURL,
            lastFMid: nil,
            url: url
        )
    }

    static func createLegacyFriend(
        username: String = "friend1",
        realName: String = "Friend One",
        playCount: Int = 100,
        imageURL: String? = nil,
        imageThumbURL: String? = nil,
        url: String? = nil
    ) -> LegacyFriend {
        LegacyFriend(
            username: username,
            realName: realName,
            playCount: playCount,
            imageURL: imageURL,
            imageThumbURL: imageThumbURL,
            url: url
        )
    }

    // MARK: - Date Utilities

    static func dateFrom(year: Int, month: Int, day: Int) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components) ?? Date()
    }

    static func dateFromTimestamp(_ timestamp: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}
