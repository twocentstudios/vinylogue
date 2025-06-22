import Dependencies
import Sharing
import SwiftUI

struct AppView: View {
    @Bindable var store: AppStore
    @State private var navigationTint: Color? = nil

    var body: some View {
        NavigationStack(path: $store.path) {
            UsersListView(store: store.usersListStore)
                .navigationDestination(for: AppStore.Path.self) { path in
                    switch path {
                    case let .weeklyAlbums(store):
                        WeeklyAlbumsView(store: store)
                    case let .albumDetail(store):
                        AlbumDetailView(store: store)
                    }
                }
        }
        .tint(navigationTint)
        .onPreferenceChange(NavigationTintPreferenceKey.self) { newTint in
            navigationTint = newTint
        }
    }
}

#Preview("App View") {
    AppView(store: AppStore())
}
