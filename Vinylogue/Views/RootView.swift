import Sharing
import SwiftUI

struct RootView: View {
    // Use @Shared directly
    @Shared(.appStorage("currentUser")) var currentUsername: String?

    @StateObject private var migrator = LegacyMigrator()
    @State private var isMigrationComplete = false
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
            if !isMigrationComplete {
                // Show loading during migration
                MigrationLoadingView()
            } else if hasCurrentUser {
                // User is logged in, show main app
                UsersListView()
            } else {
                // No user, show onboarding
                OnboardingView()
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
        await migrator.migrateIfNeeded()

        if migrator.migrationError != nil {
            showMigrationError = true
        } else {
            isMigrationComplete = true
        }
    }
}

// MARK: - Migration Loading View

private struct MigrationLoadingView: View {
    @State private var rotationAngle: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.accent)
                .rotationEffect(.degrees(rotationAngle))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }

            VStack(spacing: 8) {
                Text("Setting up Vinylogue")
                    .font(.navigationTitle)
                    .foregroundColor(.primaryText)

                Text("Migrating your data...")
                    .font(.body)
                    .foregroundColor(.secondaryText)
            }

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accent))
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
