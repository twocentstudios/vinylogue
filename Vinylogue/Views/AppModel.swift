import Dependencies
import Sharing
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var path: [Path] {
        didSet { bind() }
    }
    var usersListStore: UsersListStore {
        didSet { bind() }
    }

    @ObservationIgnored
    @Dependency(\.date) var date
    @ObservationIgnored
    @Dependency(\.calendar) var calendar

    enum Path: Hashable {
        case weeklyAlbums(WeeklyAlbumsStore, user: User)
        case albumDetail(AlbumDetailStore)
    }

    init(
        path: [Path] = [],
        usersListStore: UsersListStore = UsersListStore()
    ) {
        self.path = path
        self.usersListStore = usersListStore
        bind()
    }

    private func bind() {
        for destination in path {
            switch destination {
            case let .weeklyAlbums(weeklyAlbumsStore, user):
                bindWeeklyAlbums(store: weeklyAlbumsStore, user: user)
            case .albumDetail:
                break
            }
        }
    }

    private func bindWeeklyAlbums(store: WeeklyAlbumsStore, user: User) {
        // Set up any needed bindings for WeeklyAlbumsStore
        // For example, navigation to album detail could be handled here
    }

    // MARK: - Navigation Actions

    func navigateToWeeklyAlbums(for user: User) {
        let weeklyAlbumsStore = WeeklyAlbumsStore()
        path.append(.weeklyAlbums(weeklyAlbumsStore, user: user))
    }

    func navigateToAlbumDetail(album: Album, weekInfo: WeekInfo) {
        let albumDetailStore = AlbumDetailStore(album: album, weekInfo: weekInfo)
        path.append(.albumDetail(albumDetailStore))
    }
}
