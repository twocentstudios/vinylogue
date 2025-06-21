import SwiftUI

struct AppView: View {
    @Bindable var model: AppModel

    var body: some View {
        NavigationStack(path: $model.path) {
            UsersListView(store: model.usersListStore, appModel: model)
                .navigationDestination(for: AppModel.Path.self) { path in
                    switch path {
                    case let .weeklyAlbums(store, user):
                        WeeklyAlbumsView(user: user, store: store, appModel: model)
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
