import Sharing
import SwiftUI

struct RootView: View {
    // Use @Shared directly
    @Shared(.appStorage("currentUser")) var currentUsername: String?

    @StateObject private var migrator = LegacyMigrator()
    @State private var isMigrationComplete: Bool?
    @State private var showMigrationError = false

    // Computed property for User object (for backward compatibility)
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
                    // Migration complete, show appropriate view
                    if hasCurrentUser {
                        // User is logged in, show main app
                        UsersListView()
                    } else {
                        // No user, show onboarding
                        OnboardingView()
                    }
                } else {
                    // Show loading during migration
                    MigrationLoadingView()
                }
            } else {
                // Initial state - determine what to show without flickering
                if hasCurrentUser {
                    // User exists, show main app immediately
                    UsersListView()
                } else {
                    // No user, show onboarding immediately
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
        // Check if migration is actually needed first
        let needsMigration = UserDefaults.standard.bool(forKey: "VinylogueMigrationCompleted") == false
        
        if needsMigration {
            // Only show migration screen if we actually need to migrate
            isMigrationComplete = false
            await migrator.migrateIfNeeded()
            
            if migrator.migrationError != nil {
                showMigrationError = true
            } else {
                isMigrationComplete = true
            }
        } else {
            // No migration needed, mark as complete immediately
            isMigrationComplete = true
        }
    }
}

// MARK: - Migration Loading View

private struct MigrationLoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            AnimatedLoadingIndicator(size: 60)

            VStack(spacing: 8) {
                Text("Setting up Vinylogue")
                    .font(.navigationTitle)
                    .foregroundColor(.primaryText)

                Text("Migrating your data...")
                    .font(.body)
                    .foregroundColor(.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}

// MARK: - Placeholder Views

// UsersListView is now implemented in its own file

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
