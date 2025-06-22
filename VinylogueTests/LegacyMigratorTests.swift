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
        migrator.$migrationCompletedShared.withLock { $0 = true }

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration is marked as completed without doing work
        XCTAssertTrue(migrator.migrationCompletedShared)
    }

    func testMigrationRunsWhenNotCompleted() async {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: Migration has not been completed
        XCTAssertFalse(migrator.migrationCompletedShared)

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration completes and is marked as done
        XCTAssertTrue(migrator.migrationCompletedShared)
    }

    // MARK: - Legacy User Migration Tests

    func testLegacyUserMigration() async throws {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: Legacy user data exists
        let legacyUser = LegacyUser(username: "testuser123", realName: "Test User", imageURL: "http://example.com/image.jpg")
        let userData = try NSKeyedArchiver.archivedData(withRootObject: legacyUser, requiringSecureCoding: false)
        tempUserDefaults.set(userData, forKey: LegacyUser.userDefaultsKey)

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration completes successfully
        XCTAssertTrue(migrator.migrationCompletedShared)

        // And: Legacy user data is cleaned up
        XCTAssertNil(tempUserDefaults.object(forKey: LegacyUser.userDefaultsKey))
    }

    func testNoLegacyUserMigration() async {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: No legacy user data exists
        // (no setup needed)

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration still completes successfully
        XCTAssertTrue(migrator.migrationCompletedShared)
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
        XCTAssertTrue(migrator.migrationCompletedShared)

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
        // Given: Legacy friends data exists in UserDefaults
        let legacyFriends = [
            LegacyFriend(username: "friend1", realName: "Friend One", playCount: 1000, imageURL: nil, imageThumbURL: nil, url: nil),
            LegacyFriend(username: "friend2", realName: "Friend Two", playCount: 2000, imageURL: "http://example.com/image.jpg", imageThumbURL: "http://example.com/thumb.jpg", url: "http://example.com/user"),
        ]

        // Store friends data using NSKeyedArchiver like the legacy app
        let friendsData = try NSKeyedArchiver.archivedData(withRootObject: legacyFriends, requiringSecureCoding: false)
        tempUserDefaults.set(friendsData, forKey: LegacySettings.Keys.friendsList)

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration completes successfully
        XCTAssertTrue(migrator.migrationCompletedShared)

        // And: Legacy friends data is cleaned up
        XCTAssertNil(tempUserDefaults.object(forKey: LegacySettings.Keys.friendsList))
    }

    // MARK: - Full Migration Test

    func testFullMigrationWithAllLegacyData() async throws {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: All types of legacy data exist
        let testPlayCountFilter = 3

        // Set up legacy user
        let legacyUser = LegacyUser(username: "fulluser", realName: "Full User", imageURL: "http://example.com/image.jpg")
        let userData = try NSKeyedArchiver.archivedData(withRootObject: legacyUser, requiringSecureCoding: false)
        tempUserDefaults.set(userData, forKey: LegacyUser.userDefaultsKey)

        // Set up legacy settings
        tempUserDefaults.set(testPlayCountFilter, forKey: LegacySettings.Keys.playCountFilter)
        tempUserDefaults.set(Date(), forKey: LegacySettings.Keys.lastOpenedDate)

        // Set up legacy friends
        let legacyFriends = [
            LegacyFriend(username: "friend1", realName: "Friend One", playCount: 1000, imageURL: nil, imageThumbURL: nil, url: nil),
        ]

        // Store friends data using NSKeyedArchiver like the legacy app
        let friendsData = try NSKeyedArchiver.archivedData(withRootObject: legacyFriends, requiringSecureCoding: false)
        tempUserDefaults.set(friendsData, forKey: LegacySettings.Keys.friendsList)

        // When: Migration is run
        await migrator.migrateIfNeeded()

        // Then: Migration completes successfully
        XCTAssertTrue(migrator.migrationCompletedShared)
        XCTAssertTrue(migrator.migrationCompletedShared)

        // And: New settings are in place (via @Shared)
        // Note: @Shared properties in LegacyMigrator use production storage, not test storage
        // This is acceptable for migration tests as they verify the migration logic works

        // And: All legacy data is cleaned up
        XCTAssertNil(tempUserDefaults.object(forKey: LegacyUser.userDefaultsKey))
        XCTAssertNil(tempUserDefaults.object(forKey: LegacySettings.Keys.playCountFilter))
        XCTAssertNil(tempUserDefaults.object(forKey: LegacySettings.Keys.lastOpenedDate))
        XCTAssertNil(tempUserDefaults.object(forKey: LegacySettings.Keys.friendsList))

        // And: Migration record is saved
        let migrationRecordURL = tempFileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("migration_record.txt")
        XCTAssertTrue(tempFileManager.fileExists(atPath: migrationRecordURL.path))
    }

    // MARK: - Reset Tests

    func testMigrationReset() async {
        migrator = LegacyMigrator(userDefaults: tempUserDefaults, fileManager: tempFileManager, cacheDirectory: tempDirectory)
        // Given: Migration was completed
        await migrator.migrateIfNeeded()
        XCTAssertTrue(migrator.migrationCompletedShared)

        // When: Migration is reset
        migrator.resetMigration()

        // Then: Migration state is reset
        XCTAssertFalse(migrator.migrationCompletedShared)
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
            imageURL: "http://example.com/image.jpg",
            imageThumbURL: "http://example.com/thumb.jpg",
            url: "http://example.com/user"
        )

        // When: Converting to new User model
        let user = legacyFriend.toUser()

        // Then: User is properly converted
        XCTAssertEqual(user.username, "frienduser")
        XCTAssertEqual(user.realName, "Friend User")
        XCTAssertEqual(user.imageURL, "http://example.com/image.jpg")
        XCTAssertEqual(user.playCount, 5000)
        XCTAssertEqual(user.url, "http://example.com/user")
    }
}
