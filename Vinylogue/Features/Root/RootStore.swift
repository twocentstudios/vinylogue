import Sharing
import SwiftUI

@MainActor
@Observable
final class RootStore {
    @ObservationIgnored @Shared(.currentUser) var currentUsername
    @ObservationIgnored @Shared(.migrationCompleted) var migrationCompleted

    var migrationStore: MigrationStore? = nil
    var appStore: AppStore? = nil
    var onboardingStore: OnboardingStore? = nil

    var hasCurrentUser: Bool {
        guard let username = currentUsername else { return false }
        return !username.isEmpty
    }

    init() {}

    func updateState() {
        if !migrationCompleted, migrationStore == nil {
            migrationStore = MigrationStore()
            onboardingStore = nil
            appStore = nil
        } else if migrationCompleted, hasCurrentUser, appStore == nil {
            migrationStore = nil
            onboardingStore = nil
            appStore = AppStore()
        } else if migrationCompleted, !hasCurrentUser, onboardingStore == nil {
            migrationStore = nil
            onboardingStore = OnboardingStore()
            appStore = nil
        }
    }
}
