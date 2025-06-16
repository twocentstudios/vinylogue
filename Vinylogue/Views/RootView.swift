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

private struct UsersListView: View {
    @Environment(\.currentUser) private var currentUser
    @State private var showLogoutAlert = false
    
    // Placeholder friends data matching the screenshot
    private let placeholderFriends = [
        "BobbyStompy",
        "slippydrums", 
        "sammeadley",
        "esheikh",
        "itschinatown",
        "HelsMeaty",
        "heyimtaka0121",
        "voxmjw",
        "shortcake986"
    ]
    
    private var currentUsername: String? {
        if let user = currentUser {
            return user.username
        } else if let username = UserDefaults.standard.string(forKey: "currentUser") {
            return username
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Current user section
                if let username = currentUsername {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("me")
                                .font(.sectionHeader)
                                .foregroundColor(.tertiaryText)
                                .textCase(.lowercase)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        HStack {
                            Text(username)
                                .font(.usernameLarge)
                                .foregroundColor(.primaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
                
                // Friends section placeholder
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("friends")
                            .font(.sectionHeader)
                            .foregroundColor(.tertiaryText)
                            .textCase(.lowercase)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Placeholder friends list matching screenshot design
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(placeholderFriends, id: \.self) { friendName in
                            HStack {
                                Text(friendName)
                                    .font(.usernameRegular)
                                    .foregroundColor(.primaryText)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Spacer()
            }
            .background(Color.primaryBackground)
            .navigationTitle(currentUsername ?? "Vinylogue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showLogoutAlert = true
                    }
                    .font(.body)
                    .foregroundColor(.accent)
                }
            }
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