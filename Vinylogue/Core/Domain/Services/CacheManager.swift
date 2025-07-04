import Foundation

enum CacheError: Error, LocalizedError {
    case directoryCreationFailed
    case dataNotFound
    case invalidData
    case writeFailure(Error)
    case readFailure(Error)

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed:
            "Failed to create cache directory"
        case .dataNotFound:
            "Cached data not found"
        case .invalidData:
            "Invalid cached data format"
        case let .writeFailure(error):
            "Failed to write cache: \(error.localizedDescription)"
        case let .readFailure(error):
            "Failed to read cache: \(error.localizedDescription)"
        }
    }
}

struct CacheManager: Sendable {
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        cacheDirectory = URL.cachesDirectory.appendingPathComponent("DataCache")

        // Create cache directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            print("Warning: Failed to create cache directory: \(error)")
        }
    }

    // MARK: - Generic Caching

    func store(_ object: some Codable, key: String) async throws {
        let url = cacheDirectory.appendingPathComponent("\(key).json")

        do {
            let data = try encoder.encode(object)
            try data.write(to: url)
        } catch {
            throw CacheError.writeFailure(error)
        }
    }

    func retrieve<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(type, from: data)
        } catch {
            throw CacheError.readFailure(error)
        }
    }

    func remove(key: String) async throws {
        let url = cacheDirectory.appendingPathComponent("\(key).json")

        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        try FileManager.default.removeItem(at: url)
    }

    // MARK: - Cache Management

    func clearCache() async throws {
        guard FileManager.default.fileExists(atPath: cacheDirectory.path) else {
            return
        }

        try FileManager.default.removeItem(at: cacheDirectory)

        // Recreate the cache directory
        try FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Specific Cache Methods
}

// Legacy ChartCache for backward compatibility
struct ChartCache: Sendable {
    private let cacheManager = CacheManager()

    init() {}

    func load(user: String, from: Date, to: Date) async throws -> Data? {
        let key = CacheKeyBuilder.chart(user: user, from: from, to: to)

        do {
            let albums: [UserChartAlbum]? = try await cacheManager.retrieve([UserChartAlbum].self, key: key)
            guard let albums else {
                return nil
            }
            return try JSONEncoder().encode(albums)
        } catch {
            return nil
        }
    }

    func save(_ data: Data, user: String, from: Date, to: Date) async throws {
        let key = CacheKeyBuilder.chart(user: user, from: from, to: to)

        do {
            let albums = try JSONDecoder().decode([UserChartAlbum].self, from: data)
            try await cacheManager.store(albums, key: key)
        } catch {
            throw CacheError.writeFailure(error)
        }
    }
}
