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
                .foregroundColor(.accentColor)
                .rotationEffect(.degrees(rotationAngle))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
            
            VStack(spacing: 8) {
                Text("Setting up Vinylogue")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Migrating your data...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Placeholder Views

private struct UsersListView: View {
    @Environment(\.currentUser) private var currentUser
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 16) {
                    Text("Welcome back!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let user = currentUser {
                        Text("Logged in as \(user.username)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    } else if let username = UserDefaults.standard.string(forKey: "currentUser") {
                        Text("Logged in as \(username)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Users list and weekly charts coming in Sprint 3!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button("Sign Out") {
                    showLogoutAlert = true
                }
                .foregroundColor(.red)
            }
            .navigationTitle("Vinylogue")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private func signOut() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        // The RootView will automatically show OnboardingView when currentUser becomes nil
    }
}

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