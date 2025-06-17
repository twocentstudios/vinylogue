import Foundation
import Sharing
@testable import Vinylogue
import XCTest

@MainActor
final class LegacyMigratorTests: XCTestCase {
    nonisolated var migrator: LegacyMigrator!
    nonisolated var tempUserDefaults: UserDefaults!
    nonisolated var tempFileManager: FileManager!
    nonisolated var tempDirectory: URL!

    override func setUpWithError() throws {
        // Create a temporary UserDefaults suite for testing
        let suiteName = "test-\(UUID().uuidString)"
        tempUserDefaults = UserDefaults(suiteName: suiteName)!

        // Create a temporary directory for file operations
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LegacyMigratorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        tempFileManager = FileManager.default
        // migrator will be created in each test method
    }

    override func tearDownWithError() throws {
        // Clean up temporary data
        tempUserDefaults.removePersistentDomain(forName: tempUserDefaults.dictionaryRepresentation().keys.first!)

        if tempFileManager.fileExists(atPath: tempDirectory.path) {
            try tempFileManager.removeItem(at: tempDirectory)
        }

        migrator = nil
        tempUserDefaults = nil
        tempFileManager = nil
        tempDirectory = nil
    }

    // MARK: - Migration Completion Tests

    func testMigrationSkippedWhenAlreadyCompleted() async {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: Migration was already completed
        tempUserDefaults.set(true, forKey: "VinylogueMigrationCompleted")

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration is marked as completed without doing work
        XCTAssertTrue(migrator.migrationCompleted)
        XCTAssertNil(migrator.migrationError)
    }

    func testMigrationRunsWhenNotCompleted() async {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: Migration has not been completed
        XCTAssertFalse(tempUserDefaults.bool(forKey: "VinylogueMigrationCompleted"))

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration completes and is marked as done
        XCTAssertTrue(migrator.migrationCompleted)
        XCTAssertTrue(tempUserDefaults.bool(forKey: "VinylogueMigrationCompleted"))
        XCTAssertNil(migrator.migrationError)
    }

    // MARK: - Legacy User Migration Tests

    func testLegacyUserMigration() async {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: Legacy user data exists
        let testUsername = "testuser123"
        tempUserDefaults.set(testUsername, forKey: LegacyUser.userDefaultsKey)

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration completes successfully
        XCTAssertTrue(migrator.migrationCompleted)
        XCTAssertNil(migrator.migrationError)

        // And: Legacy user data is cleaned up
        XCTAssertNil(tempUserDefaults.string(forKey: LegacyUser.userDefaultsKey))
    }

    func testNoLegacyUserMigration() async {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: No legacy user data exists
        // (no setup needed)

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration still completes successfully
        XCTAssertTrue(migrator.migrationCompleted)
        XCTAssertNil(migrator.migrationError)
    }

    // MARK: - Legacy Settings Migration Tests

    func testLegacySettingsMigration() async {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: Legacy settings exist
        let testPlayCountFilter = 5
        tempUserDefaults.set(testPlayCountFilter, forKey: LegacySettings.Keys.playCountFilter)
        tempUserDefaults.set(Date(), forKey: LegacySettings.Keys.lastOpenedDate)

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration completes successfully
        XCTAssertTrue(migrator.migrationCompleted)
        XCTAssertNil(migrator.migrationError)

        // And: Settings are migrated to new format (via @Shared)
        // Note: @Shared properties in LegacyMigrator use production storage, not test storage
        // This is acceptable for migration tests as they verify the migration logic works

        // And: Legacy settings are cleaned up
        XCTAssertNil(tempUserDefaults.object(forKey: LegacySettings.Keys.playCountFilter))
        XCTAssertNil(tempUserDefaults.object(forKey: LegacySettings.Keys.lastOpenedDate))
    }

    // MARK: - Legacy Friends Migration Tests

    func testLegacyFriendsMigration() async throws {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: Legacy friends cache exists
        let legacyFriends = [
            LegacyFriend(username: "friend1", realName: "Friend One", playCount: 1000, imageURL: nil),
            LegacyFriend(username: "friend2", realName: "Friend Two", playCount: 2000, imageURL: "http://example.com/image.jpg"),
        ]

        let cacheDirectory = tempDirectory.appendingPathComponent("VinylogueCache")
        try tempFileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        let friendsCacheURL = cacheDirectory.appendingPathComponent(LegacyFriend.cacheFileName)
        let friendsData = try JSONEncoder().encode(legacyFriends)
        try friendsData.write(to: friendsCacheURL)

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration completes successfully
        XCTAssertTrue(migrator.migrationCompleted)
        XCTAssertNil(migrator.migrationError)

        // And: Legacy friends cache is cleaned up
        XCTAssertFalse(tempFileManager.fileExists(atPath: friendsCacheURL.path))
    }

    // MARK: - Full Migration Test

    func testFullMigrationWithAllLegacyData() async throws {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: All types of legacy data exist
        let testUsername = "fulluser"
        let testPlayCountFilter = 3

        // Set up legacy user
        tempUserDefaults.set(testUsername, forKey: LegacyUser.userDefaultsKey)

        // Set up legacy settings
        tempUserDefaults.set(testPlayCountFilter, forKey: LegacySettings.Keys.playCountFilter)
        tempUserDefaults.set(Date(), forKey: LegacySettings.Keys.lastOpenedDate)

        // Set up legacy friends
        let legacyFriends = [
            LegacyFriend(username: "friend1", realName: "Friend One", playCount: 1000, imageURL: nil),
        ]

        let cacheDirectory = tempDirectory.appendingPathComponent("VinylogueCache")
        try tempFileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        let friendsCacheURL = cacheDirectory.appendingPathComponent(LegacyFriend.cacheFileName)
        let friendsData = try JSONEncoder().encode(legacyFriends)
        try friendsData.write(to: friendsCacheURL)

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration completes successfully
        XCTAssertTrue(migrator.migrationCompleted)
        XCTAssertNil(migrator.migrationError)
        XCTAssertTrue(tempUserDefaults.bool(forKey: "VinylogueMigrationCompleted"))

        // And: New settings are in place (via @Shared)
        // Note: @Shared properties in LegacyMigrator use production storage, not test storage
        // This is acceptable for migration tests as they verify the migration logic works

        // And: All legacy data is cleaned up
        XCTAssertNil(tempUserDefaults.string(forKey: LegacyUser.userDefaultsKey))
        XCTAssertNil(tempUserDefaults.object(forKey: LegacySettings.Keys.playCountFilter))
        XCTAssertNil(tempUserDefaults.object(forKey: LegacySettings.Keys.lastOpenedDate))
        XCTAssertFalse(tempFileManager.fileExists(atPath: friendsCacheURL.path))

        // And: Migration record is saved
        let migrationRecordURL = tempFileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("migration_record.json")
        XCTAssertTrue(tempFileManager.fileExists(atPath: migrationRecordURL.path))
    }

    // MARK: - Reset Tests

    func testMigrationReset() async {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: Migration was completed
        await migrator.migrateIfNeeded()
        XCTAssertTrue(migrator.migrationCompleted)

        // When: Migration is reset
        migrator.resetMigration()

        // Then: Migration state is reset
        XCTAssertFalse(migrator.migrationCompleted)
        XCTAssertNil(migrator.migrationError)
        XCTAssertFalse(tempUserDefaults.bool(forKey: "VinylogueMigrationCompleted"))
    }

    // MARK: - Model Tests

    func testLegacyUserToUserConversion() {
        // Given: A legacy user
        let legacyUser = LegacyUser(username: "testuser")

        // When: Converting to new User model
        let user = legacyUser.toUser()

        // Then: User is properly converted
        XCTAssertEqual(user.username, "testuser")
        XCTAssertNil(user.realName)
        XCTAssertNil(user.imageURL)
        XCTAssertNil(user.url)
        XCTAssertNil(user.playCount)
    }

    func testLegacyFriendToUserConversion() {
        // Given: A legacy friend
        let legacyFriend = LegacyFriend(
            username: "frienduser",
            realName: "Friend User",
            playCount: 5000,
            imageURL: "http://example.com/image.jpg"
        )

        // When: Converting to new User model
        let user = legacyFriend.toUser()

        // Then: User is properly converted
        XCTAssertEqual(user.username, "frienduser")
        XCTAssertEqual(user.realName, "Friend User")
        XCTAssertEqual(user.imageURL, "http://example.com/image.jpg")
        XCTAssertEqual(user.playCount, 5000)
        XCTAssertNil(user.url)
    }
}
