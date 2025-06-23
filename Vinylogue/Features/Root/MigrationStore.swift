import SwiftUI

@MainActor
@Observable
final class MigrationStore {
    var migrator = LegacyMigrator()

    init() {}

    func migrateIfNeeded() async {
        await migrator.migrateIfNeeded()
    }
}
