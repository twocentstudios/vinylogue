import Sharing
import SwiftUI

@MainActor
@Observable
final class RootStore {
    @ObservationIgnored @Shared(.currentUser) var currentUsername: String?
    @ObservationIgnored @Shared(.migrationCompleted) var migrationCompleted

    var migrator = LegacyMigrator()
    var isMigrationComplete: Bool?
    var showMigrationError = false

    var appModel = AppModel()

    var currentUser: User? {
        guard let username = currentUsername else { return nil }
        return User(
            username: username,
            realName: nil,
            imageURL: nil,
            url: nil,
            playCount: nil
        )
    }

    var hasCurrentUser: Bool {
        guard let username = currentUsername else { return false }
        return !username.isEmpty
    }

    init() {}

    func performMigration() async {
        let needsMigration = !migrationCompleted

        if needsMigration {
            isMigrationComplete = false
            await migrator.migrateIfNeeded()

            if migrator.migrationError != nil {
                showMigrationError = true
            } else {
                isMigrationComplete = true
            }
        } else {
            isMigrationComplete = true
        }
    }

    func retryMigration() async {
        await performMigration()
    }

    func continueAnyway() {
        isMigrationComplete = true
    }
}
