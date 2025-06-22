import Dependencies
import Sharing
import SwiftUI

@MainActor
@Observable
final class AppStore {
    @ObservationIgnored
    @Shared(.navigationPath) var path: [Path]

    let usersListStore: UsersListStore

    enum Path: Hashable {
        case weeklyAlbums(WeeklyAlbumsStore)
        case albumDetail(AlbumDetailStore)
    }

    init(
        usersListStore: UsersListStore = UsersListStore()
    ) {
        self.usersListStore = usersListStore
    }
}
