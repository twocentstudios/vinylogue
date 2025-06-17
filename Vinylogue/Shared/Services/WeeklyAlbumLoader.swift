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
    private let cacheManager = CacheManager()
    private var playCountFilter: Int = 1
    private var weeklyCharts: [ChartPeriod] = []

    // Track loaded state to prevent unnecessary reloads
    private var loadedUsername: String?
    private var loadedYearOffset: Int?
    private var loadedPlayCountFilter: Int?

    struct WeekInfo {
        let weekNumber: Int
        let year: Int
        let username: String

        var displayText: String {
            "WEEK \(weekNumber) of \(year)"
        }
    }

    init(lastFMClient: LastFMClientProtocol = LastFMClient.shared) {
        self.lastFMClient = lastFMClient
    }

    /// Update the play count filter and reload if necessary
    func updatePlayCountFilter(_ newFilter: Int, for user: User, yearOffset: Int) async {
        guard newFilter != playCountFilter else { return }

        playCountFilter = newFilter

        // If we have data loaded for this user/year, refilter and update
        if loadedUsername == user.username, loadedYearOffset == yearOffset {
            await loadAlbums(for: user, yearOffset: yearOffset, forceReload: true)
        }
    }

    /// Check if albums are already loaded for the given user and year offset
    func isDataLoaded(for user: User, yearOffset: Int, playCountFilter: Int) -> Bool {
        loadedUsername == user.username &&
            loadedYearOffset == yearOffset &&
            loadedPlayCountFilter == playCountFilter &&
            !albums.isEmpty
    }

    /// Load albums for a specific user and year offset
    func loadAlbums(for user: User, yearOffset: Int = 0, forceReload: Bool = false) async {
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
                loadedPlayCountFilter = nil
                isLoading = false
                return
            }

            // Update week info
            let calendar = Calendar.current
            let weekNumber = calendar.component(.weekOfYear, from: chartPeriod.fromDate)
            let year = calendar.component(.yearForWeekOfYear, from: chartPeriod.fromDate)
            currentWeekInfo = WeekInfo(weekNumber: weekNumber, year: year, username: user.username)

            // Try to load from cache first (unless force reload)
            let cacheKey = "weekly_chart_\(user.username)_\(Int(chartPeriod.fromDate.timeIntervalSince1970))_\(Int(chartPeriod.toDate.timeIntervalSince1970))"
            var response: UserWeeklyAlbumChartResponse?

            if !forceReload {
                response = try? await cacheManager.retrieve(UserWeeklyAlbumChartResponse.self, key: cacheKey)
            }

            if response == nil {
                // Fetch from API and cache the result
                response = try await lastFMClient.request(
                    .userWeeklyAlbumChart(
                        username: user.username,
                        from: chartPeriod.fromDate,
                        to: chartPeriod.toDate
                    )
                )

                // Cache the response
                if let validResponse = response {
                    try await cacheManager.store(validResponse, key: cacheKey)
                }
            }

            guard let finalResponse = response else {
                throw LastFMError.invalidResponse
            }

            // Convert to Album objects and filter by play count
            let filteredAlbums = (finalResponse.weeklyalbumchart.album ?? [])
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
            loadedPlayCountFilter = playCountFilter
            isLoading = false

        } catch let lastFMError as LastFMError {
            error = lastFMError
            albums = []
            currentWeekInfo = nil
            loadedUsername = nil
            loadedYearOffset = nil
            loadedPlayCountFilter = nil
            isLoading = false
        } catch {
            self.error = .invalidResponse
            albums = []
            currentWeekInfo = nil
            loadedUsername = nil
            loadedYearOffset = nil
            loadedPlayCountFilter = nil
            isLoading = false
        }
    }

    /// Load the available weekly chart periods for a user
    private func loadWeeklyChartList(for username: String) async {
        do {
            let cacheKey = "weekly_chart_list_\(username)"

            // Try to load from cache first
            var response: UserWeeklyChartListResponse?
            response = try? await cacheManager.retrieve(UserWeeklyChartListResponse.self, key: cacheKey)

            if response == nil {
                // Fetch from API and cache the result
                response = try await lastFMClient.request(
                    .userWeeklyChartList(username: username)
                )

                // Cache the response
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
        loadedPlayCountFilter = nil
    }
}
