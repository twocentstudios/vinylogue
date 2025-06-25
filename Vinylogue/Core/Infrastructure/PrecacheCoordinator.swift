import Dependencies
import Foundation
import Nuke
import OSLog

/// Actor responsible for coordinating and cancelling precaching operations
actor PrecacheCoordinator {
    private let logger = Logger(subsystem: "com.twocentstudios.vinylogue", category: "PrecacheCoordinator")

    private var activePrecacheTasks: [String: Task<Void, Never>] = [:]
    private var activePrefetchers: [String: ImagePrefetcher] = [:]
    private var memoryPressureTask: Task<Void, Never>?

    @Dependency(\.memoryPressureMonitor) private var memoryPressureMonitor

    enum CancellationReason: String, Sendable {
        case userNavigation = "User Navigation"
        case memoryPressure = "Memory Pressure"
        case networkDegraded = "Network Degraded"
        case explicit = "Explicit Request"
        case deallocation = "Store Deallocation"
        case viewDisappeared = "View Disappeared"
    }

    init() {
        Task {
            await startMemoryPressureMonitoring()
        }
    }

    private func startMemoryPressureMonitoring() {
        memoryPressureTask = Task { [weak self] in
            guard let self else { return }

            for await pressure in await memoryPressureMonitor.pressureUpdates {
                if pressure >= .moderate {
                    await cancelAllPrecaching(reason: .memoryPressure)
                }
            }
        }
    }

    /// Starts a new precaching operation with the given key
    func startPrecaching(
        key: String,
        priority: TaskPriority = .utility,
        operation: @escaping @Sendable () async throws -> Void
    ) {
        // Cancel existing task with same key to prevent duplicates
        cancelPrecaching(key: key, reason: .explicit)

        let task = Task(priority: priority) {
            do {
                try await operation()
                logger.info("Precaching completed successfully for key: \(key)")
            } catch is CancellationError {
                logger.info("Precaching cancelled for key: \(key)")
            } catch {
                logger.warning("Precaching failed for key: \(key) - \(error.localizedDescription)")
            }

            // Clean up on completion
            self.cleanupTask(key: key)
        }

        activePrecacheTasks[key] = task
        logger.info("Started precaching for key: \(key)")
    }

    /// Cancels precaching for a specific key
    func cancelPrecaching(key: String, reason: CancellationReason) {
        activePrecacheTasks[key]?.cancel()
        activePrecacheTasks.removeValue(forKey: key)

        // Cancel associated image prefetching
        activePrefetchers[key]?.stopPrefetching()
        activePrefetchers.removeValue(forKey: key)

        logger.info("Cancelled precaching for key: \(key), reason: \(reason.rawValue)")
    }

    /// Cancels all active precaching operations
    func cancelAllPrecaching(reason: CancellationReason) {
        let cancelledCount = activePrecacheTasks.count + activePrefetchers.count

        for key in activePrecacheTasks.keys {
            activePrecacheTasks[key]?.cancel()
        }
        activePrecacheTasks.removeAll()

        for prefetcher in activePrefetchers.values {
            prefetcher.stopPrefetching()
        }
        activePrefetchers.removeAll()

        if cancelledCount > 0 {
            logger.info("Cancelled \(cancelledCount) precaching operations, reason: \(reason.rawValue)")
        }
    }

    /// Registers an image prefetcher for cancellation management
    func registerImagePrefetcher(_ prefetcher: ImagePrefetcher, key: String) {
        activePrefetchers[key] = prefetcher
    }

    /// Checks if there are any active precaching operations
    var hasActivePrecaching: Bool {
        !activePrecacheTasks.isEmpty || !activePrefetchers.isEmpty
    }

    /// Gets the count of active operations for debugging
    var activeOperationCount: (tasks: Int, prefetchers: Int) {
        (activePrecacheTasks.count, activePrefetchers.count)
    }

    private func cleanupTask(key: String) {
        activePrecacheTasks.removeValue(forKey: key)
    }

    deinit {
        memoryPressureTask?.cancel()

        // Cancel all active operations
        for task in activePrecacheTasks.values {
            task.cancel()
        }
        for prefetcher in activePrefetchers.values {
            prefetcher.stopPrefetching()
        }
    }
}

// MARK: - Dependency

extension PrecacheCoordinator: DependencyKey {
    static let liveValue = PrecacheCoordinator()

    static let testValue: PrecacheCoordinator = // For tests, create a new instance that won't interfere with other tests
        .init()

    static let previewValue: PrecacheCoordinator = // For previews, use the same as test
        .init()
}

extension DependencyValues {
    var precacheCoordinator: PrecacheCoordinator {
        get { self[PrecacheCoordinator.self] }
        set { self[PrecacheCoordinator.self] = newValue }
    }
}
