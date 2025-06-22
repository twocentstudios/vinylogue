import Foundation
import Observation
import OSLog
import Sharing

/// Service responsible for migrating legacy data to the new format
@Observable
@MainActor
final class LegacyMigrator {
    @ObservationIgnored private let logger = Logger(subsystem: "com.twocentstudios.vinylogue", category: "LegacyMigrator")
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let fileManager: FileManager
    @ObservationIgnored private let cacheDirectory: URL?

    /// Indicates if migration has been completed
    var migrationCompleted: Bool = false

    /// Any migration error that occurred
    var migrationError: Error?
    
    var hasMigrationError: Bool {
        migrationError != nil
    }

    // @Shared properties for data persistence (excluded from observation)
    @ObservationIgnored @Shared(.currentUser) var currentUsername: String?
    @ObservationIgnored @Shared(.currentPlayCountFilter) var playCountFilter
    @ObservationIgnored @Shared(.curatedFriends) var curatedFriends
    @ObservationIgnored @Shared(.migrationCompleted) var migrationCompletedShared

    init(userDefaults: UserDefaults = .standard, fileManager: FileManager = .default, cacheDirectory: URL? = nil) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        self.cacheDirectory = cacheDirectory
    }

    /// Performs migration if needed. Safe to call multiple times.
    func migrateIfNeeded() async {
        // Check if migration was already completed
        if migrationCompletedShared {
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
            $migrationCompletedShared.withLock { $0 = true }
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

    /// Loads legacy user data from UserDefaults (NSKeyedArchiver format)
    private func loadLegacyUser() -> LegacyUser? {
        guard let userData = userDefaults.object(forKey: LegacyUser.userDefaultsKey) as? Data else {
            logger.info("No legacy user data found")
            return nil
        }

        do {
            // Set up class name mapping for legacy User class to new LegacyUser class
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: userData)
            unarchiver.requiresSecureCoding = false
            unarchiver.setClass(LegacyUser.self, forClassName: "User")

            if let legacyUser = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? LegacyUser {
                unarchiver.finishDecoding()
                logger.info("Found legacy user: \(legacyUser.username) (realName: \(legacyUser.realName ?? "nil"))")
                return legacyUser
            }
            unarchiver.finishDecoding()
        } catch {
            logger.warning("Failed to unarchive legacy user data: \(error.localizedDescription)")
        }

        logger.info("No valid legacy user found")
        return nil
    }

    /// Loads legacy settings from UserDefaults
    private func loadLegacySettings() -> LegacySettings? {
        // The legacy app stored playCountFilter as NSNumber (NSUInteger in Objective-C)
        let playCountFilterNumber = userDefaults.object(forKey: LegacySettings.Keys.playCountFilter) as? NSNumber
        let playCountFilter = playCountFilterNumber?.intValue
        let lastOpenedDate = userDefaults.object(forKey: LegacySettings.Keys.lastOpenedDate) as? Date

        // Only create settings object if we have some data
        guard playCountFilter != nil || lastOpenedDate != nil else {
            logger.info("No legacy settings found")
            return nil
        }

        logger.info("Found legacy settings - playCountFilter: \(playCountFilter?.description ?? "nil")")
        return LegacySettings(playCountFilter: playCountFilter, lastOpenedDate: lastOpenedDate)
    }

    /// Loads legacy friends data from UserDefaults (NSKeyedArchiver format)
    private func loadLegacyFriends() async -> [LegacyFriend]? {
        guard let friendsData = userDefaults.object(forKey: LegacySettings.Keys.friendsList) as? Data else {
            logger.info("No legacy friends data found")
            return nil
        }

        do {
            // Set up class name mapping for legacy User class to new LegacyFriend class
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: friendsData)
            unarchiver.requiresSecureCoding = false
            unarchiver.setClass(LegacyFriend.self, forClassName: "User")

            if let friendsArray = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [LegacyFriend] {
                unarchiver.finishDecoding()
                logger.info("Found \(friendsArray.count) legacy friends")
                return friendsArray.isEmpty ? nil : friendsArray
            }
            unarchiver.finishDecoding()
        } catch {
            logger.warning("Failed to unarchive legacy friends data: \(error.localizedDescription)")
        }

        return nil
    }

    /// Migrates legacy data to new format using @Shared properties
    private func migrateLegacyData(_ legacyData: LegacyData) async {
        // Migrate user data
        if let legacyUser = legacyData.user {
            let newUser = legacyUser.toUser()
            $currentUsername.withLock { $0 = newUser.username }
            logger.info("Migrated user: \(newUser.username)")
        }

        // Migrate settings
        if let legacySettings = legacyData.settings {
            if let legacyPlayCountFilter = legacySettings.playCountFilter {
                $playCountFilter.withLock { $0 = legacyPlayCountFilter }
                logger.info("Migrated playCountFilter: \(legacyPlayCountFilter)")
            }
        }

        // Migrate friends data using @Shared
        if let legacyFriends = legacyData.friends {
            let newUsers = legacyFriends.map { $0.toUser() }
            $curatedFriends.withLock { $0 = newUsers }
            logger.info("Migrated \(newUsers.count) friends using @Shared")
        }

        // Save migration record
        await saveMigrationRecord(legacyData)
    }

    /// Saves a record of the migration for debugging purposes
    private func saveMigrationRecord(_ legacyData: LegacyData) async {
        do {
            let migrationURL = getDocumentsDirectory().appendingPathComponent("migration_record.txt")
            let recordText = """
            Migration completed on: \(legacyData.migrationDate)
            User found: \(legacyData.user?.username ?? "none")
            Settings found: \(legacyData.settings != nil ? "yes" : "no")
            Friends found: \(legacyData.friends?.count ?? 0)
            """
            try recordText.write(to: migrationURL, atomically: true, encoding: .utf8)
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
        userDefaults.removeObject(forKey: LegacySettings.Keys.friendsList)

        logger.info("Cleaned up legacy data")
    }

    /// Force a re-migration (for testing purposes)
    func resetMigration() {
        $migrationCompletedShared.withLock { $0 = false }
        migrationCompleted = false
        migrationError = nil
        logger.info("Reset migration state")
    }
}

// MARK: - Private Helpers

private extension LegacyMigrator {
    func getCacheDirectory() -> URL {
        if let cacheDirectory {
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
        case let .dataCorrupted(message):
            "Data corrupted: \(message)"
        case let .migrationFailed(message):
            "Migration failed: \(message)"
        case let .cleanupFailed(message):
            "Cleanup failed: \(message)"
        }
    }
}
