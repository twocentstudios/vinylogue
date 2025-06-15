import Foundation

struct ChartCache {
    private let cacheDirectory: URL
    
    init() {
        self.cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("VinylogueCache")
        
        // Create cache directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }
    
    func load(user: String, from: Date, to: Date) async throws -> Data? {
        let url = cacheURL(user: user, from: from, to: to)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        return try Data(contentsOf: url)
    }
    
    func save(_ data: Data, user: String, from: Date, to: Date) async throws {
        let userDirectory = cacheDirectory.appendingPathComponent(user)
        
        // Create user directory if it doesn't exist
        try FileManager.default.createDirectory(
            at: userDirectory,
            withIntermediateDirectories: true
        )
        
        let url = cacheURL(user: user, from: from, to: to)
        try data.write(to: url)
    }
    
    private func cacheURL(user: String, from: Date, to: Date) -> URL {
        let fromTimestamp = Int(from.timeIntervalSince1970)
        let toTimestamp = Int(to.timeIntervalSince1970)
        let filename = "\(fromTimestamp)-\(toTimestamp).json"
        
        return cacheDirectory
            .appendingPathComponent(user)
            .appendingPathComponent(filename)
    }
}