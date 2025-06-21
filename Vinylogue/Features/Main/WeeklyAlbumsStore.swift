import Dependencies
import Foundation
import Nuke
import Observation
import SwiftUI

enum WeeklyAlbumsLoadingState: Equatable {
    case initialized
    case loading
    case loaded([Album])
    case failed(LastFMError)
}

struct WeekInfo: Hashable {
    let weekNumber: Int
    let year: Int
    let username: String

    var displayText: String {
        "WEEK \(weekNumber) of \(year)"
    }
}

@Observable
@MainActor
final class WeeklyAlbumsStore: Hashable {
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
    @ObservationIgnored @Dependency(\.imagePipeline) private var imagePipeline
    @ObservationIgnored @Dependency(\.date) private var date
    @ObservationIgnored @Dependency(\.calendar) private var calendar
    @ObservationIgnored private var playCountFilter: Int = 1
    @ObservationIgnored private var weeklyCharts: [ChartPeriod] = []

    @ObservationIgnored private var loadedUsername: String?
    @ObservationIgnored private var loadedYearOffset: Int?
    @ObservationIgnored private var loadedPlayCountFilter: Int?

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

            let cacheKey = CacheKeyBuilder.weeklyChart(username: user.username, from: chartPeriod.fromDate, to: chartPeriod.toDate)
            var response: UserWeeklyAlbumChartResponse?

            if !forceReload {
                do {
                    response = try await cacheManager.retrieve(UserWeeklyAlbumChartResponse.self, key: cacheKey)
                } catch {
                    print("Cache retrieval failed for weekly chart \(cacheKey): \(error)")
                    response = nil
                }
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

            // Trigger precaching for previous year data (non-blocking)
            let previousYearOffset = yearOffset + 1
            if canNavigate(to: previousYearOffset) {
                Task { [weak self] in
                    guard let self else { return }
                    let targetDate = calculateTargetDate(yearOffset: previousYearOffset)
                    guard let chartPeriod = findMatchingChartPeriod(for: targetDate) else { return }

                    await precacheDataForYear(
                        user: user,
                        chartPeriod: chartPeriod,
                        playCountFilter: playCountFilter,
                        lastFMClient: lastFMClient,
                        cacheManager: cacheManager,
                        imagePipeline: imagePipeline
                    )
                }
            }

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
            let cacheKey = CacheKeyBuilder.weeklyChartList(username: username)

            var response: UserWeeklyChartListResponse?
            do {
                response = try await cacheManager.retrieve(UserWeeklyChartListResponse.self, key: cacheKey)
            } catch {
                print("Cache retrieval failed for weekly chart list \(cacheKey): \(error)")
                response = nil
            }

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

    /// Precache images for a collection of albums (used for performance optimization)
    private func precacheImages(for albums: [Album]) async {
        // Filter albums to get only those with valid image URLs
        let imageURLs = albums.compactMap { album -> URL? in
            guard let imageURLString = album.imageURL,
                  !imageURLString.isEmpty,
                  let url = URL(string: imageURLString)
            else {
                return nil
            }
            return url
        }

        // Only proceed if we have URLs to prefetch
        guard !imageURLs.isEmpty else { return }

        // Create prefetcher with disk-only caching for memory efficiency
        let prefetcher = ImagePrefetcher(pipeline: imagePipeline, destination: .diskCache)

        // Start prefetching all album images
        prefetcher.startPrefetching(with: imageURLs)

        // Note: We don't wait for completion or handle errors since this is a background optimization
        // The ImagePrefetcher will automatically manage the download lifecycle
    }

    /// Precache images for a collection of albums (nonisolated version)
    private nonisolated func precacheImages(for albums: [Album], imagePipeline: ImagePipeline) async {
        // Filter albums to get only those with valid image URLs
        let imageURLs = albums.compactMap { album -> URL? in
            guard let imageURLString = album.imageURL,
                  !imageURLString.isEmpty,
                  let url = URL(string: imageURLString)
            else {
                return nil
            }
            return url
        }

        // Only proceed if we have URLs to prefetch
        guard !imageURLs.isEmpty else { return }

        // Create prefetcher with disk-only caching for memory efficiency
        let prefetcher = ImagePrefetcher(pipeline: imagePipeline, destination: .diskCache)

        // Start prefetching all album images
        prefetcher.startPrefetching(with: imageURLs)

        // Note: We don't wait for completion or handle errors since this is a background optimization
        // The ImagePrefetcher will automatically manage the download lifecycle
    }

    /// Precache data for a specific year offset (used for performance optimization)
    private nonisolated func precacheDataForYear(
        user: User,
        chartPeriod: ChartPeriod,
        playCountFilter: Int,
        lastFMClient: LastFMClientProtocol,
        cacheManager: CacheManager,
        imagePipeline: ImagePipeline
    ) async {
        do {
            let cacheKey = CacheKeyBuilder.weeklyChart(username: user.username, from: chartPeriod.fromDate, to: chartPeriod.toDate)

            // Check if already cached
            do {
                if let _ = try await cacheManager.retrieve(UserWeeklyAlbumChartResponse.self, key: cacheKey) {
                    return // Already cached
                }
            } catch {
                print("Cache check failed for precaching \(cacheKey): \(error)")
                // Continue to fetch and cache
            }

            // Fetch and cache the weekly chart response
            let response: UserWeeklyAlbumChartResponse = try await lastFMClient.request(
                .userWeeklyAlbumChart(
                    username: user.username,
                    from: chartPeriod.fromDate,
                    to: chartPeriod.toDate
                )
            )

            try await cacheManager.store(response, key: cacheKey)

            // Process albums and precache their details
            let albums = (response.weeklyalbumchart.album ?? [])
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

            // Load album details and then precache images
            let populatedAlbums = await withTaskGroup(of: Album?.self) { group in
                // Limit concurrent requests to avoid overwhelming the API and memory
                let maxConcurrentRequests = 5
                var activeTaskCount = 0

                // Precache album details
                for album in albums {
                    // Wait if we've reached the concurrency limit
                    if activeTaskCount >= maxConcurrentRequests {
                        _ = await group.next()
                        activeTaskCount -= 1
                    }

                    group.addTask {
                        do {
                            let detailedAlbum = try await lastFMClient.fetchAlbumInfo(
                                artist: album.artist,
                                album: album.name,
                                mbid: album.mbid,
                                username: user.username
                            )
                            return detailedAlbum
                        } catch {
                            // Return nil for failed requests
                            return nil
                        }
                    }
                    activeTaskCount += 1
                }

                // Collect all results
                var results: [Album] = []
                for await result in group {
                    if let album = result {
                        results.append(album)
                    }
                }
                return results
            }

            // Now precache images using albums with populated imageURL
            await precacheImages(for: populatedAlbums, imagePipeline: imagePipeline)

        } catch {
            // Ignore errors in precaching - it's a performance optimization
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

    // MARK: - Hashable

    nonisolated static func == (lhs: WeeklyAlbumsStore, rhs: WeeklyAlbumsStore) -> Bool {
        // For navigation purposes, we'll use object identity
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
