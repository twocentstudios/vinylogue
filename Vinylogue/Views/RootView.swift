import Sharing
import SwiftUI

struct RootView: View {
    @Bindable var store: RootStore

    var body: some View {
        Group {
            if let migrationComplete = store.isMigrationComplete {
                if migrationComplete {
                    if store.hasCurrentUser {
                        UsersListView(store: store.usersListStore)
                    } else {
                        OnboardingView()
                    }
                } else {
                    MigrationLoadingView()
                }
            } else {
                if store.hasCurrentUser {
                    UsersListView(store: store.usersListStore)
                } else {
                    OnboardingView()
                }
            }
        }
        .task {
            await store.performMigration()
        }
        .alert("Migration Error", isPresented: $store.showMigrationError) {
            Button("Continue Anyway") {
                store.continueAnyway()
            }
            Button("Retry") {
                Task {
                    await store.retryMigration()
                }
            }
        } message: {
            if let error = store.migrator.migrationError {
                Text("Failed to migrate legacy data: \(error.localizedDescription)")
            }
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
    RootView(store: RootStore())
}

#Preview("Root - With User") {
    let store = RootStore()
    return RootView(store: store)
        .onAppear {
            store.$currentUsername.withLock { $0 = "testuser" }
        }
}

#Preview("Migration Loading") {
    MigrationLoadingView()
}

#Preview("Users List") {
    UsersListView(store: UsersListStore())
}
