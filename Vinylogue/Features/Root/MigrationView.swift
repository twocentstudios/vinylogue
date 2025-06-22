import SwiftUI

struct MigrationView: View {
    @Bindable var store: MigrationStore
    
    var body: some View {
        Color.primaryBackground.ignoresSafeArea()
            .task {
                await store.migrateIfNeeded()
            }
    }
}

#Preview {
    MigrationView(store: MigrationStore())
}