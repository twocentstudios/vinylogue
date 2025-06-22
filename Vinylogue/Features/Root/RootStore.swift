import Sharing
import SwiftUI

@MainActor
@Observable
final class RootStore {
    @ObservationIgnored @Shared(.currentUser) var currentUsername
    @ObservationIgnored @Shared(.migrationCompleted) var migrationCompleted

    var migrator: LegacyMigrator? = nil
    var appModel: AppModel? = nil
    var onboardingStore: OnboardingStore? = nil

    var hasCurrentUser: Bool {
        guard let username = currentUsername else { return false }
        return !username.isEmpty
    }

    init() {}

    func updateState() {
        if !migrationCompleted, migrator == nil {
            migrator = LegacyMigrator()
            onboardingStore = nil
            appModel = nil
        } else if migrationCompleted, hasCurrentUser, appModel == nil {
            migrator = nil
            onboardingStore = nil
            appModel = AppModel()
        } else if migrationCompleted, !hasCurrentUser, onboardingStore == nil {
            migrator = nil
            onboardingStore = OnboardingStore()
            appModel = nil
        }
    }

    func retryMigration() async {
        await migrator?.migrateIfNeeded()
    }

    func continueAnyway() {
        $migrationCompleted.withLock { $0 = true }
    }
}
