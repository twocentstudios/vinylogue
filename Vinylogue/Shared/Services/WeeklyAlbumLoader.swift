import Foundation
import SwiftUI

@MainActor
final class WeeklyAlbumLoader: ObservableObject {
    @Published var albums: [Album] = []
    @Published var isLoading = false
    @Published var error: LastFMError?
    @Published var currentWeekInfo: WeekInfo?
    @Published var availableYearRange: ClosedRange<Int>?

    private let lastFMClient: LastFMClientProtocol
    private let playCountFilter: Int
    private var weeklyCharts: [ChartPeriod] = []

    // Track loaded state to prevent unnecessary reloads
    private var loadedUsername: String?
    private var loadedYearOffset: Int?

    struct WeekInfo {
        let weekNumber: Int
        let year: Int
        let username: String

        var displayText: String {
            "WEEK \(weekNumber) of \(year)"
        }
    }

    init(lastFMClient: LastFMClientProtocol = LastFMClient.shared, playCountFilter: Int = 1) {
        self.lastFMClient = lastFMClient
        self.playCountFilter = playCountFilter
    }

    /// Check if albums are already loaded for the given user and year offset
    func isDataLoaded(for user: User, yearOffset: Int) -> Bool {
        loadedUsername == user.username &&
            loadedYearOffset == yearOffset &&
            !albums.isEmpty
    }

    /// Load albums for a specific user and year offset
    func loadAlbums(for user: User, yearOffset: Int = 0) async {
        isLoading = true
        error = nil

        do {
            // First, get the weekly chart list if we don't have it
            if weeklyCharts.isEmpty {
                await loadWeeklyChartList(for: user.username)
            }

            // Calculate the target date (same week N years ago)
            let targetDate = calculateTargetDate(yearOffset: yearOffset)

            // Find the matching weekly chart period
            guard let chartPeriod = findMatchingChartPeriod(for: targetDate) else {
                albums = []
                currentWeekInfo = nil
                error = .noDataAvailable
                loadedUsername = nil
                loadedYearOffset = nil
                isLoading = false
                return
            }

            // Update week info
            let calendar = Calendar.current
            let weekNumber = calendar.component(.weekOfYear, from: chartPeriod.fromDate)
            let year = calendar.component(.yearForWeekOfYear, from: chartPeriod.fromDate)
            currentWeekInfo = WeekInfo(weekNumber: weekNumber, year: year, username: user.username)

            // Fetch the weekly album chart
            let response: UserWeeklyAlbumChartResponse = try await lastFMClient.request(
                .userWeeklyAlbumChart(
                    username: user.username,
                    from: chartPeriod.fromDate,
                    to: chartPeriod.toDate
                )
            )

            // Convert to Album objects and filter by play count
            let filteredAlbums = (response.weeklyalbumchart.album ?? [])
                .filter { $0.playCount >= playCountFilter }
                .map { albumEntry in
                    Album(
                        name: albumEntry.name,
                        artist: albumEntry.artist.name,
                        imageURL: nil, // Will be loaded lazily
                        playCount: albumEntry.playCount,
                        rank: albumEntry.rankNumber,
                        url: albumEntry.url,
                        mbid: albumEntry.mbid
                    )
                }
                .sorted { $0.playCount > $1.playCount }

            albums = filteredAlbums

            // Update tracking state on successful load
            loadedUsername = user.username
            loadedYearOffset = yearOffset
            isLoading = false

        } catch let lastFMError as LastFMError {
            error = lastFMError
            albums = []
            currentWeekInfo = nil
            loadedUsername = nil
            loadedYearOffset = nil
            isLoading = false
        } catch {
            self.error = .invalidResponse
            albums = []
            currentWeekInfo = nil
            loadedUsername = nil
            loadedYearOffset = nil
            isLoading = false
        }
    }

    /// Load the available weekly chart periods for a user
    private func loadWeeklyChartList(for username: String) async {
        do {
            let response: UserWeeklyChartListResponse = try await lastFMClient.request(
                .userWeeklyChartList(username: username)
            )

            weeklyCharts = response.weeklychartlist.chart ?? []

            // Calculate available year range
            if let firstChart = weeklyCharts.first,
               let lastChart = weeklyCharts.last
            {
                let calendar = Calendar.current
                let earliestYear = calendar.component(.year, from: firstChart.fromDate)
                let latestYear = calendar.component(.year, from: lastChart.toDate)
                availableYearRange = earliestYear ... latestYear
            }

        } catch {
            // If we can't load the chart list, we'll handle it gracefully
            weeklyCharts = []
            availableYearRange = nil
        }
    }

    /// Calculate the target date for a given year offset
    private func calculateTargetDate(yearOffset: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()

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
        let calendar = Calendar.current
        let targetDate = calculateTargetDate(yearOffset: yearOffset)
        return calendar.component(.year, from: targetDate)
    }

    /// Check if navigation to a specific year offset is available
    func canNavigate(to yearOffset: Int) -> Bool {
        guard let yearRange = availableYearRange else { return false }
        let targetYear = getYear(for: yearOffset)
        return yearRange.contains(targetYear)
    }

    /// Clear all data
    func clear() {
        albums = []
        currentWeekInfo = nil
        error = nil
        isLoading = false
        loadedUsername = nil
        loadedYearOffset = nil
    }
}
