import Dependencies
import Foundation
import Observation
import SwiftUI

enum WeeklyAlbumsLoadingState: Equatable {
    case initialized
    case loading
    case loaded([Album])
    case failed(LastFMError)
}

@Observable
@MainActor
final class WeeklyAlbumLoader {
    var albumsState: WeeklyAlbumsLoadingState = .initialized
    var currentWeekInfo: WeekInfo?
    var availableYearRange: ClosedRange<Int>?

    /// Computed property to provide access to albums array for binding purposes
    var albums: [Album] {
        get {
            if case let .loaded(albums) = albumsState {
                return albums
            }
            return []
        }
        set {
            albumsState = .loaded(newValue)
        }
    }

    @ObservationIgnored @Dependency(\.lastFMClient) private var lastFMClient
    @ObservationIgnored @Dependency(\.cacheManager) private var cacheManager
    @ObservationIgnored @Dependency(\.date) private var date
    @ObservationIgnored @Dependency(\.calendar) private var calendar
    @ObservationIgnored private var playCountFilter: Int = 1
    @ObservationIgnored private var weeklyCharts: [ChartPeriod] = []

    @ObservationIgnored private var loadedUsername: String?
    @ObservationIgnored private var loadedYearOffset: Int?
    @ObservationIgnored private var loadedPlayCountFilter: Int?

    struct WeekInfo {
        let weekNumber: Int
        let year: Int
        let username: String

        var displayText: String {
            "WEEK \(weekNumber) of \(year)"
        }
    }

    init() {}

    /// Update the play count filter and reload if necessary
    func updatePlayCountFilter(_ newFilter: Int, for user: User, yearOffset: Int) async {
        guard newFilter != playCountFilter else { return }

        playCountFilter = newFilter

        if loadedUsername == user.username, loadedYearOffset == yearOffset {
            await loadAlbums(for: user, yearOffset: yearOffset, forceReload: true)
        }
    }

    /// Check if albums are already loaded for the given user and year offset
    func isDataLoaded(for user: User, yearOffset: Int, playCountFilter: Int) -> Bool {
        guard case .loaded = albumsState else { return false }
        return loadedUsername == user.username &&
            loadedYearOffset == yearOffset &&
            loadedPlayCountFilter == playCountFilter
    }

    /// Load albums for a specific user and year offset
    func loadAlbums(for user: User, yearOffset: Int = 0, forceReload: Bool = false) async {
        albumsState = .loading

        do {
            if weeklyCharts.isEmpty {
                await loadWeeklyChartList(for: user.username)
            }

            let targetDate = calculateTargetDate(yearOffset: yearOffset)

            guard let chartPeriod = findMatchingChartPeriod(for: targetDate) else {
                albumsState = .failed(.noDataAvailable)
                currentWeekInfo = nil
                loadedUsername = nil
                loadedYearOffset = nil
                loadedPlayCountFilter = nil
                return
            }

            let weekNumber = calendar.component(.weekOfYear, from: chartPeriod.fromDate)
            let year = calendar.component(.yearForWeekOfYear, from: chartPeriod.fromDate)
            currentWeekInfo = WeekInfo(weekNumber: weekNumber, year: year, username: user.username)

            let cacheKey = "weekly_chart_\(user.username)_\(Int(chartPeriod.fromDate.timeIntervalSince1970))_\(Int(chartPeriod.toDate.timeIntervalSince1970))"
            var response: UserWeeklyAlbumChartResponse?

            if !forceReload {
                response = try? await cacheManager.retrieve(UserWeeklyAlbumChartResponse.self, key: cacheKey)
            }

            if response == nil {
                response = try await lastFMClient.request(
                    .userWeeklyAlbumChart(
                        username: user.username,
                        from: chartPeriod.fromDate,
                        to: chartPeriod.toDate
                    )
                )

                if let validResponse = response {
                    try await cacheManager.store(validResponse, key: cacheKey)
                }
            }

            guard let finalResponse = response else {
                throw LastFMError.invalidResponse
            }

            let filteredAlbums = (finalResponse.weeklyalbumchart.album ?? [])
                .filter { $0.playCount > playCountFilter }
                .map { albumEntry in
                    Album(
                        name: albumEntry.name,
                        artist: albumEntry.artist.name,
                        imageURL: nil,
                        playCount: albumEntry.playCount,
                        rank: albumEntry.rankNumber,
                        url: albumEntry.url,
                        mbid: albumEntry.mbid
                    )
                }
                .sorted { $0.playCount > $1.playCount }

            albumsState = .loaded(filteredAlbums)

            loadedUsername = user.username
            loadedYearOffset = yearOffset
            loadedPlayCountFilter = playCountFilter

        } catch let lastFMError as LastFMError {
            albumsState = .failed(lastFMError)
            currentWeekInfo = nil
            loadedUsername = nil
            loadedYearOffset = nil
            loadedPlayCountFilter = nil
        } catch {
            albumsState = .failed(.invalidResponse)
            currentWeekInfo = nil
            loadedUsername = nil
            loadedYearOffset = nil
            loadedPlayCountFilter = nil
        }
    }

    /// Load the available weekly chart periods for a user
    private func loadWeeklyChartList(for username: String) async {
        do {
            let cacheKey = "weekly_chart_list_\(username)"

            var response: UserWeeklyChartListResponse?
            response = try? await cacheManager.retrieve(UserWeeklyChartListResponse.self, key: cacheKey)

            if response == nil {
                response = try await lastFMClient.request(
                    .userWeeklyChartList(username: username)
                )

                if let validResponse = response {
                    try await cacheManager.store(validResponse, key: cacheKey)
                }
            }

            guard let finalResponse = response else {
                weeklyCharts = []
                availableYearRange = nil
                return
            }

            weeklyCharts = finalResponse.weeklychartlist.chart ?? []

            if let firstChart = weeklyCharts.first,
               let lastChart = weeklyCharts.last
            {
                let earliestYear = calendar.component(.year, from: firstChart.fromDate)
                let latestYear = calendar.component(.year, from: lastChart.toDate)
                availableYearRange = earliestYear ... latestYear
            }

        } catch {
            weeklyCharts = []
            availableYearRange = nil
        }
    }

    /// Calculate the target date for a given year offset
    private func calculateTargetDate(yearOffset: Int) -> Date {
        let now = date()

        var components = DateComponents()
        components.year = -yearOffset

        return calendar.date(byAdding: components, to: now) ?? now
    }

    /// Find the weekly chart period that contains the target date
    private func findMatchingChartPeriod(for targetDate: Date) -> ChartPeriod? {
        weeklyCharts.first { chartPeriod in
            chartPeriod.fromDate <= targetDate && targetDate <= chartPeriod.toDate
        }
    }

    /// Get the year for a given offset (for navigation button display)
    func getYear(for yearOffset: Int) -> Int {
        let targetDate = calculateTargetDate(yearOffset: yearOffset)
        return calendar.component(.year, from: targetDate)
    }

    /// Check if navigation to a specific year offset is available
    func canNavigate(to yearOffset: Int) -> Bool {
        guard let yearRange = availableYearRange else { return false }

        if yearOffset == 0 { return false }

        let targetYear = getYear(for: yearOffset)
        return yearRange.contains(targetYear)
    }

    /// Load album details for a specific album
    func loadAlbum(_ album: Album, for user: User) async {
        do {
            let detailedAlbum = try await lastFMClient.fetchAlbumInfo(
                artist: album.artist,
                album: album.name,
                mbid: album.mbid,
                username: user.username
            )

            // Find and update the album in our stored collection
            if let index = albums.firstIndex(where: { $0.id == album.id }) {
                albums[index].imageURL = detailedAlbum.imageURL
                albums[index].description = detailedAlbum.description
                albums[index].totalPlayCount = detailedAlbum.totalPlayCount
                albums[index].userPlayCount = detailedAlbum.userPlayCount
                albums[index].isDetailLoaded = true
            }
        } catch {
            // Find and update the album in our stored collection
            if let index = albums.firstIndex(where: { $0.id == album.id }) {
                albums[index].imageURL = nil
            }
        }
    }

    /// Clear all data
    func clear() {
        albumsState = .initialized
        currentWeekInfo = nil
        loadedUsername = nil
        loadedYearOffset = nil
        loadedPlayCountFilter = nil
    }
}
