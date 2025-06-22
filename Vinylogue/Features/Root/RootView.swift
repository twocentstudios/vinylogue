import Sharing
import SwiftUI

struct RootView: View {
    @Bindable var store: RootStore

    var body: some View {
        ZStack {
            if let legacyMigrator = store.migrator {
                MigrationLoadingView()
                    .task {
                        await legacyMigrator.migrateIfNeeded()
                    }
            } else if let onboardingStore = store.onboardingStore {
                OnboardingView(store: onboardingStore)
            } else if let appModel = store.appModel {
                AppView(model: appModel)
            } else {
                Color.primaryBackground.ignoresSafeArea()
            }
        }
        .task {
            store.updateState()
        }
        .onChange(of: store.hasCurrentUser) { _, _ in
            store.updateState()
        }
        .onChange(of: store.migrationCompleted) { _, _ in
            store.updateState()
        }
//        .alert("Migration Error", isPresented: store.migrator?.hasMigrationError) {
//            Button("Continue Anyway") {
//                store.continueAnyway()
//            }
//            Button("Retry") {
//                Task {
//                    await store.retryMigration()
//                }
//            }
//        } message: {
//            if let error = store.migrator?.migrationError {
//                Text("Failed to migrate legacy data: \(error.localizedDescription)")
//            }
//        }
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
    RootView(store: store)
        .onAppear {
            store.$currentUsername.withLock { $0 = "testuser" }
        }
}

#Preview("Migration Loading") {
    MigrationLoadingView()
}

#Preview("App View") {
    AppView(model: AppModel())
}
