import Dependencies
import Foundation
import Nuke
import Observation
import Sharing
import SwiftUI

enum WeeklyAlbumsLoadingState: Equatable {
    case initialized
    case loading
    case loaded([UserChartAlbum])
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
    var user: User
    var currentYearOffset: Int = 1
    @ObservationIgnored @Shared(.currentPlayCountFilter) var playCountFilter
    @ObservationIgnored @Shared(.navigationPath) var navigationPath: [AppStore.Path]

    /// Computed property to provide access to albums array for binding purposes
    var albums: [UserChartAlbum] {
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
    @ObservationIgnored @Dependency(\.imagePipeline) var imagePipeline
    @ObservationIgnored @Dependency(\.precacheCoordinator) private var precacheCoordinator
    @ObservationIgnored @Dependency(\.date) private var date
    @ObservationIgnored @Dependency(\.calendar) private var calendar
    @ObservationIgnored private var weeklyCharts: [ChartPeriod] = []

    @ObservationIgnored private var loadedUsername: String?
    @ObservationIgnored private var loadedYearOffset: Int?
    @ObservationIgnored private var loadedPlayCountFilter: Int?
    @ObservationIgnored private var isViewActive = true

    init(user: User, currentYearOffset: Int = 1) {
        self.user = user
        self.currentYearOffset = currentYearOffset
    }

    /// Check if albums are already loaded for the current user and year offset
    func isDataLoaded() -> Bool {
        guard case .loaded = albumsState else { return false }
        return loadedUsername == user.username &&
            loadedYearOffset == currentYearOffset &&
            loadedPlayCountFilter == playCountFilter
    }

    /// Load albums for the current user and year offset
    func loadAlbums(forceReload: Bool = false) async {
        guard !isDataLoaded() else { return }

        albumsState = .loading

        do {
            if weeklyCharts.isEmpty {
                await loadWeeklyChartList(for: user.username)
            }

            let targetDate = calculateTargetDate(yearOffset: currentYearOffset)

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
                    UserChartAlbum(
                        username: user.username,
                        weekNumber: weekNumber,
                        year: year,
                        name: albumEntry.name,
                        artist: albumEntry.artist.name,
                        playCount: albumEntry.playCount,
                        rank: albumEntry.rankNumber,
                        url: albumEntry.url,
                        mbid: albumEntry.mbid
                    )
                }
                .sorted { $0.playCount > $1.playCount }

            albumsState = .loaded(filteredAlbums)

            loadedUsername = user.username
            loadedYearOffset = currentYearOffset
            loadedPlayCountFilter = playCountFilter

            // Trigger precaching for previous year data (non-blocking)
            let previousYearOffset = currentYearOffset + 1
            if canNavigate(to: previousYearOffset) {
                let precacheKey = "year-\(previousYearOffset)-\(user.username)"

                await precacheCoordinator.startPrecaching(key: precacheKey) { [weak self] in
                    guard let self, await isViewActive else {
                        throw CancellationError()
                    }

                    let targetDate = await calculateTargetDate(yearOffset: previousYearOffset)
                    guard let chartPeriod = await findMatchingChartPeriod(for: targetDate) else {
                        return
                    }

                    try await precacheDataForYearWithCancellation(
                        user: user,
                        chartPeriod: chartPeriod,
                        playCountFilter: playCountFilter,
                        lastFMClient: lastFMClient,
                        cacheManager: cacheManager,
                        imagePipeline: imagePipeline,
                        calendar: calendar,
                        precacheKey: precacheKey
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
    func loadAlbum(_ album: UserChartAlbum) async {
        do {
            let detailedAlbum = try await lastFMClient.fetchAlbumInfo(
                artist: album.artist,
                album: album.name,
                mbid: album.mbid,
                username: user.username
            )

            // Find and update the album in our stored collection
            var currentAlbums = albums
            if let index = currentAlbums.firstIndex(where: { $0.id == album.id }) {
                currentAlbums[index].detail = UserChartAlbum.Detail(
                    imageURL: detailedAlbum.imageURL,
                    description: detailedAlbum.description,
                    totalPlayCount: detailedAlbum.totalPlayCount,
                    userPlayCount: detailedAlbum.userPlayCount
                )
                albums = currentAlbums
            }
        } catch {
            // Find and update the album in our stored collection
            var currentAlbums = albums
            if let index = currentAlbums.firstIndex(where: { $0.id == album.id }) {
                currentAlbums[index].detail = UserChartAlbum.Detail(
                    imageURL: nil,
                    description: nil,
                    totalPlayCount: nil,
                    userPlayCount: nil
                )
                albums = currentAlbums
            }
        }
    }

    /// Precache images for a collection of albums (used for performance optimization)
    private func precacheImages(for albums: [UserChartAlbum]) async {
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
    private nonisolated func precacheImages(for albums: [UserChartAlbum], imagePipeline: ImagePipeline) async {
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
        let requests = imageURLs.map { ImageRequest(url: $0, processors: [], priority: .veryLow, options: .disableMemoryCacheWrites, userInfo: nil) }
        prefetcher.startPrefetching(with: requests)

        // Note: We don't wait for completion or handle errors since this is a background optimization
        // The ImagePrefetcher will automatically manage the download lifecycle
    }

    /// Precache images with cancellation support (nonisolated version for coordinator)
    private nonisolated func precacheImagesWithCancellation(
        for albums: [UserChartAlbum],
        imagePipeline: ImagePipeline,
        precacheKey: String
    ) async throws {
        try Task.checkCancellation()

        let imageURLs = albums.compactMap { album -> URL? in
            guard let imageURLString = album.imageURL,
                  !imageURLString.isEmpty,
                  let url = URL(string: imageURLString)
            else { return nil }
            return url
        }

        guard !imageURLs.isEmpty else { return }

        // Create cancellable image prefetcher
        let prefetcher = ImagePrefetcher(pipeline: imagePipeline, destination: .diskCache)

        // Create low-priority requests
        let requests = imageURLs.map { url in
            ImageRequest(
                url: url,
                processors: [],
                priority: .veryLow,
                options: [.disableMemoryCacheWrites],
                userInfo: ["precacheKey": precacheKey]
            )
        }

        // Register prefetcher for potential cancellation
        @Dependency(\.precacheCoordinator) var coordinator
        await coordinator.registerImagePrefetcher(prefetcher, key: precacheKey)

        // Start prefetching with cancellation handling
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                prefetcher.didComplete = {
                    continuation.resume()
                }
                prefetcher.startPrefetching(with: requests)
            }
        } onCancel: {
            prefetcher.stopPrefetching()
        }
    }

    /// Precache data for a specific year offset with cancellation support
    private nonisolated func precacheDataForYearWithCancellation(
        user: User,
        chartPeriod: ChartPeriod,
        playCountFilter: Int,
        lastFMClient: LastFMClientProtocol,
        cacheManager: CacheManager,
        imagePipeline: ImagePipeline,
        calendar: Calendar,
        precacheKey: String
    ) async throws {
        // Check cancellation at entry
        try Task.checkCancellation()

        do {
            let cacheKey = CacheKeyBuilder.weeklyChart(username: user.username, from: chartPeriod.fromDate, to: chartPeriod.toDate)

            // Check if already cached
            do {
                if let _ = try await cacheManager.retrieve(UserWeeklyAlbumChartResponse.self, key: cacheKey) {
                    return // Already cached
                }
            } catch {
                try Task.checkCancellation()
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

            try Task.checkCancellation()
            try await cacheManager.store(response, key: cacheKey)

            // Extract week info for chart context
            let weekNumber = calendar.component(.weekOfYear, from: chartPeriod.fromDate)
            let year = calendar.component(.yearForWeekOfYear, from: chartPeriod.fromDate)

            // Process albums and precache their details
            let albums = (response.weeklyalbumchart.album ?? [])
                .filter { $0.playCount > playCountFilter }
                .map { albumEntry in
                    UserChartAlbum(
                        username: user.username,
                        weekNumber: weekNumber,
                        year: year,
                        name: albumEntry.name,
                        artist: albumEntry.artist.name,
                        playCount: albumEntry.playCount,
                        rank: albumEntry.rankNumber,
                        url: albumEntry.url,
                        mbid: albumEntry.mbid
                    )
                }

            // Load album details and then precache images with cancellation support
            let populatedAlbums = try await withThrowingTaskGroup(of: UserChartAlbum?.self) { group in
                var results: [UserChartAlbum] = []
                var activeTaskCount = 0
                let maxConcurrentRequests = 5

                // Precache album details
                for album in albums {
                    // Respect cancellation
                    try Task.checkCancellation()

                    // Wait if we've reached the concurrency limit
                    if activeTaskCount >= maxConcurrentRequests {
                        if let result = try await group.next() {
                            if let album = result {
                                results.append(album)
                            }
                        }
                        activeTaskCount -= 1
                    }

                    group.addTask {
                        // Cooperative cancellation in each task
                        try Task.checkCancellation()

                        do {
                            let detailedAlbum = try await lastFMClient.fetchAlbumInfo(
                                artist: album.artist,
                                album: album.name,
                                mbid: album.mbid,
                                username: user.username
                            )

                            try Task.checkCancellation()

                            // Create a copy with detail populated
                            var albumWithDetail = album
                            albumWithDetail.detail = UserChartAlbum.Detail(
                                imageURL: detailedAlbum.imageURL,
                                description: detailedAlbum.description,
                                totalPlayCount: detailedAlbum.totalPlayCount,
                                userPlayCount: detailedAlbum.userPlayCount
                            )
                            return albumWithDetail
                        } catch is CancellationError {
                            throw CancellationError()
                        } catch {
                            // Return nil for other errors
                            return nil
                        }
                    }
                    activeTaskCount += 1
                }

                // Collect remaining results
                while activeTaskCount > 0 {
                    if let result = try await group.next() {
                        if let album = result {
                            results.append(album)
                        }
                    }
                    activeTaskCount -= 1
                }

                return results
            }

            // Now precache images using albums with populated imageURL
            try await precacheImagesWithCancellation(
                for: populatedAlbums,
                imagePipeline: imagePipeline,
                precacheKey: precacheKey
            )

        } catch {
            // Ignore errors in precaching - it's a performance optimization
        }
    }

    /// Navigate to album detail
    func navigateToAlbum(_ album: UserChartAlbum) {
        guard let weekInfo = currentWeekInfo else { return }
        let albumDetailStore = withDependencies(from: self) {
            AlbumDetailStore(album: album, weekInfo: weekInfo)
        }
        $navigationPath.withLock { $0.append(.albumDetail(albumDetailStore)) }
    }

    /// Clear all data
    func clear() {
        albumsState = .initialized
        currentWeekInfo = nil
        loadedUsername = nil
        loadedYearOffset = nil
        loadedPlayCountFilter = nil
    }

    /// Lifecycle management for view appearance
    func viewDidAppear() {
        isViewActive = true
    }

    /// Lifecycle management for view disappearance
    func viewWillDisappear() {
        isViewActive = false
        Task {
            await precacheCoordinator.cancelAllPrecaching(reason: .viewDisappeared)
        }
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
