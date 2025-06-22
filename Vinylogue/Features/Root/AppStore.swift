import Dependencies
import Sharing
import SwiftUI

@MainActor
@Observable
final class AppStore {
    @ObservationIgnored
    @Shared(.navigationPath) var path: [Path]

    var usersListStore: UsersListStore {
        didSet { bind() }
    }

    @ObservationIgnored
    @Dependency(\.date) var date
    @ObservationIgnored
    @Dependency(\.calendar) var calendar

    enum Path: Hashable {
        case weeklyAlbums(WeeklyAlbumsStore)
        case albumDetail(AlbumDetailStore)
    }

    init(
        usersListStore: UsersListStore = UsersListStore()
    ) {
        self.usersListStore = usersListStore
        bind()
    }

    private func bind() {
        for destination in path {
            switch destination {
            case let .weeklyAlbums(weeklyAlbumsStore):
                bindWeeklyAlbums(store: weeklyAlbumsStore)
            case .albumDetail:
                break
            }
        }
    }

    private func bindWeeklyAlbums(store: WeeklyAlbumsStore) {
        // Set up any needed bindings for WeeklyAlbumsStore
        // For example, navigation to album detail could be handled here
    }
}