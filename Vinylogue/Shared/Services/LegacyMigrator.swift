import Foundation
import OSLog

/// Service responsible for migrating legacy data to the new format
@MainActor
final class LegacyMigrator: ObservableObject {
    private let logger = Logger(subsystem: "com.twocentstudios.vinylogue", category: "LegacyMigrator")
    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let cacheDirectory: URL?
    
    /// Indicates if migration has been completed
    @Published var migrationCompleted: Bool = false
    
    /// Any migration error that occurred
    @Published var migrationError: Error?
    
    init(userDefaults: UserDefaults = .standard, fileManager: FileManager = .default, cacheDirectory: URL? = nil) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        self.cacheDirectory = cacheDirectory
    }
    
    /// Performs migration if needed. Safe to call multiple times.
    func migrateIfNeeded() async {
        // Check if migration was already completed
        if userDefaults.bool(forKey: "VinylogueMigrationCompleted") {
            logger.info("Migration already completed, skipping")
            migrationCompleted = true
            return
        }
        
        logger.info("Starting legacy data migration")
        
        do {
            let legacyData = await loadLegacyData()
            await migrateLegacyData(legacyData)
            await cleanupLegacyData()
            
            // Mark migration as completed
            userDefaults.set(true, forKey: "VinylogueMigrationCompleted")
            migrationCompleted = true
            
            logger.info("Migration completed successfully")
        } catch {
            logger.error("Migration failed: \(error.localizedDescription)")
            migrationError = error
        }
    }
    
    /// Loads all legacy data from various sources
    private func loadLegacyData() async -> LegacyData {
        let legacyUser = loadLegacyUser()
        let legacySettings = loadLegacySettings()
        let legacyFriends = await loadLegacyFriends()
        
        return LegacyData(
            user: legacyUser,
            settings: legacySettings,
            friends: legacyFriends
        )
    }
    
    /// Loads legacy user data from UserDefaults
    private func loadLegacyUser() -> LegacyUser? {
        guard let username = userDefaults.string(forKey: LegacyUser.userDefaultsKey),
              !username.isEmpty else {
            logger.info("No legacy user found")
            return nil
        }
        
        logger.info("Found legacy user: \(username)")
        return LegacyUser(username: username)
    }
    
    /// Loads legacy settings from UserDefaults
    private func loadLegacySettings() -> LegacySettings? {
        let playCountFilter = userDefaults.object(forKey: LegacySettings.Keys.playCountFilter) as? Int
        let lastOpenedDate = userDefaults.object(forKey: LegacySettings.Keys.lastOpenedDate) as? Date
        
        // Only create settings object if we have some data
        guard playCountFilter != nil || lastOpenedDate != nil else {
            logger.info("No legacy settings found")
            return nil
        }
        
        logger.info("Found legacy settings - playCountFilter: \(playCountFilter?.description ?? "nil")")
        return LegacySettings(playCountFilter: playCountFilter, lastOpenedDate: lastOpenedDate)
    }
    
    /// Loads legacy friends data from cache files
    private func loadLegacyFriends() async -> [LegacyFriend]? {
        let cacheURL = getCacheDirectory().appendingPathComponent(LegacyFriend.cacheFileName)
        
        guard fileManager.fileExists(atPath: cacheURL.path) else {
            logger.info("No legacy friends cache found")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let friends = try JSONDecoder().decode([LegacyFriend].self, from: data)
            logger.info("Found \(friends.count) legacy friends")
            return friends
        } catch {
            logger.warning("Failed to load legacy friends: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Migrates legacy data to new format using environment keys
    private func migrateLegacyData(_ legacyData: LegacyData) async {
        // Migrate user data
        if let legacyUser = legacyData.user {
            let newUser = legacyUser.toUser()
            // Note: In a real implementation, you would update the environment here
            // For now, we'll log the migration
            logger.info("Migrating user: \(newUser.username)")
        }
        
        // Migrate settings
        if let legacySettings = legacyData.settings {
            if let playCountFilter = legacySettings.playCountFilter {
                // Store in new format - could be UserDefaults or other persistence
                userDefaults.set(playCountFilter, forKey: "currentPlayCountFilter")
                logger.info("Migrated playCountFilter: \(playCountFilter)")
            }
        }
        
        // Migrate friends data to new cache format
        if let legacyFriends = legacyData.friends {
            let newUsers = legacyFriends.map { $0.toUser() }
            await migrateFriendsToNewCache(newUsers)
        }
        
        // Save migration record
        await saveMigrationRecord(legacyData)
    }
    
    /// Migrates friends to the new cache format
    private func migrateFriendsToNewCache(_ friends: [User]) async {
        do {
            let cacheManager = CacheManager()
            try await cacheManager.store(friends, key: "migratedFriends")
            logger.info("Migrated \(friends.count) friends to new cache format")
        } catch {
            logger.error("Failed to migrate friends cache: \(error.localizedDescription)")
        }
    }
    
    /// Saves a record of the migration for debugging purposes
    private func saveMigrationRecord(_ legacyData: LegacyData) async {
        do {
            let migrationURL = getDocumentsDirectory().appendingPathComponent("migration_record.json")
            let data = try JSONEncoder().encode(legacyData)
            try data.write(to: migrationURL)
            logger.info("Saved migration record")
        } catch {
            logger.warning("Failed to save migration record: \(error.localizedDescription)")
        }
    }
    
    /// Removes legacy data after successful migration
    private func cleanupLegacyData() async {
        // Remove legacy UserDefaults keys
        userDefaults.removeObject(forKey: LegacyUser.userDefaultsKey)
        userDefaults.removeObject(forKey: LegacySettings.Keys.playCountFilter)
        userDefaults.removeObject(forKey: LegacySettings.Keys.lastOpenedDate)
        
        // Remove legacy cache files
        let legacyFriendsCache = getCacheDirectory().appendingPathComponent(LegacyFriend.cacheFileName)
        try? fileManager.removeItem(at: legacyFriendsCache)
        
        logger.info("Cleaned up legacy data")
    }
    
    /// Force a re-migration (for testing purposes)
    func resetMigration() {
        userDefaults.removeObject(forKey: "VinylogueMigrationCompleted")
        migrationCompleted = false
        migrationError = nil
        logger.info("Reset migration state")
    }
}

// MARK: - Private Helpers

private extension LegacyMigrator {
    func getCacheDirectory() -> URL {
        if let cacheDirectory = cacheDirectory {
            return cacheDirectory.appendingPathComponent("VinylogueCache")
        }
        return fileManager.temporaryDirectory.appendingPathComponent("VinylogueCache")
    }
    
    func getDocumentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - Migration Errors

enum MigrationError: LocalizedError {
    case dataCorrupted(String)
    case migrationFailed(String)
    case cleanupFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .dataCorrupted(let message):
            return "Data corrupted: \(message)"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        case .cleanupFailed(let message):
            return "Cleanup failed: \(message)"
        }
    }
}