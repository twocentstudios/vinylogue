import Sharing
import SwiftUI

struct RootView: View {
    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.appStorage("migration_completed_1_3_1")) var migrationCompleted: Bool = false

    @State private var migrator = LegacyMigrator()
    @State private var isMigrationComplete: Bool?
    @State private var showMigrationError = false

    private var currentUser: User? {
        guard let username = currentUsername else { return nil }
        return User(
            username: username,
            realName: nil,
            imageURL: nil,
            url: nil,
            playCount: nil
        )
    }

    var body: some View {
        Group {
            if let migrationComplete = isMigrationComplete {
                if migrationComplete {
                    if hasCurrentUser {
                        UsersListView()
                    } else {
                        OnboardingView()
                    }
                } else {
                    MigrationLoadingView()
                }
            } else {
                if hasCurrentUser {
                    UsersListView()
                } else {
                    OnboardingView()
                }
            }
        }
        .task {
            await performMigration()
        }
        .alert("Migration Error", isPresented: $showMigrationError) {
            Button("Continue Anyway") {
                isMigrationComplete = true
            }
            Button("Retry") {
                Task {
                    await performMigration()
                }
            }
        } message: {
            if let error = migrator.migrationError {
                Text("Failed to migrate legacy data: \(error.localizedDescription)")
            }
        }
    }

    private var hasCurrentUser: Bool {
        currentUsername != nil && !currentUsername!.isEmpty
    }

    @MainActor
    private func performMigration() async {
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
}

// MARK: - Migration Loading View

private struct MigrationLoadingView: View {
    var body: some View {
        Color.primaryBackground.ignoresSafeArea()
    }
}

// MARK: - Previews

#Preview("Root - No User") {
    RootView()
        .environment(\.lastFMClient, LastFMClient())
}

#Preview("Root - With User") {
    let rootView = RootView()
    return rootView
        .environment(\.lastFMClient, LastFMClient())
        .onAppear {
            rootView.$currentUsername.withLock { $0 = "testuser" }
        }
}

#Preview("Migration Loading") {
    MigrationLoadingView()
}

#Preview("Users List") {
    UsersListView()
}
