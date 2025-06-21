import SwiftUI

struct AppView: View {
    @Bindable var model: AppModel

    var body: some View {
        NavigationStack(path: $model.path) {
            UsersListView(
                store: model.usersListStore,
                onUserTap: { user in
                    model.navigateToWeeklyAlbums(for: user)
                }
            )
            .navigationDestination(for: AppModel.Path.self) { path in
                switch path {
                case let .weeklyAlbums(store, user):
                    WeeklyAlbumsView(
                        user: user,
                        store: store,
                        onAlbumTap: { album, weekInfo in
                            model.navigateToAlbumDetail(album: album, weekInfo: weekInfo)
                        }
                    )
                case let .albumDetail(store):
                    AlbumDetailView(store: store)
                }
            }
        }
    }
}

#Preview("App View") {
    AppView(model: AppModel())
}
