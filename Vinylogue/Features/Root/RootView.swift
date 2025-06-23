import Sharing
import SwiftUI

struct RootView: View {
    @Bindable var store: RootStore

    var body: some View {
        ZStack {
            if let migrationStore = store.migrationStore {
                MigrationView(store: migrationStore)
            } else if let onboardingStore = store.onboardingStore {
                OnboardingView(store: onboardingStore)
            } else if let appStore = store.appStore {
                AppView(store: appStore)
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
    }
}

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
