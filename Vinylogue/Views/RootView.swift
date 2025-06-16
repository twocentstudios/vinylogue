import SwiftUI

struct RootView: View {
    @Environment(\.currentUser) private var currentUser
    @StateObject private var migrator = LegacyMigrator()
    @State private var isMigrationComplete = false
    @State private var showMigrationError = false
    
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
        // Check both environment and UserDefaults for current user
        if currentUser != nil {
            return true
        }
        
        // Fallback to UserDefaults check
        let username = UserDefaults.standard.string(forKey: "currentUser")
        return username != nil && !username!.isEmpty
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
    RootView()
        .environment(\.lastFMClient, LastFMClient())
        .onAppear {
            UserDefaults.standard.set("testuser", forKey: "currentUser")
        }
}

#Preview("Migration Loading") {
    MigrationLoadingView()
}

#Preview("Users List") {
    UsersListView()
        .environment(\.currentUser, User(username: "testuser", realName: "Test User", imageURL: nil, url: nil, playCount: 1000))
}