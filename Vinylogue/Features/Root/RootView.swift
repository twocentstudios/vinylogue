import Sharing
import SwiftUI

struct RootView: View {
    @Bindable var store: RootStore

    var body: some View {
        Group {
            if let migrationComplete = store.isMigrationComplete {
                if migrationComplete {
                    if store.hasCurrentUser {
                        AppView(model: store.appModel)
                    } else {
                        AppView(model: store.appModel)
                            .onAppear {
                                if store.onboardingStore == nil {
                                    store.showOnboarding()
                                }
                            }
                            .sheet(item: $store.onboardingStore) { onboardingStore in
                                OnboardingView(store: onboardingStore)
                            }
                    }
                } else {
                    MigrationLoadingView()
                }
            } else {
                if store.hasCurrentUser {
                    AppView(model: store.appModel)
                } else {
                    AppView(model: store.appModel)
                        .onAppear {
                            if store.onboardingStore == nil {
                                store.showOnboarding()
                            }
                        }
                        .sheet(item: $store.onboardingStore) { onboardingStore in
                            OnboardingView(store: onboardingStore)
                        }
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

#Preview("App View") {
    AppView(model: AppModel())
}
