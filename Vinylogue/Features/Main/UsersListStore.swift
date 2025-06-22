import Dependencies
import Sharing
import SwiftUI

@MainActor
@Observable
final class UsersListStore {
    @ObservationIgnored @Shared(.currentUser) var currentUsername: String?
    @ObservationIgnored @Shared(.curatedFriends) var curatedFriends
    @ObservationIgnored @Shared(.navigationPath) var navigationPath: [AppModel.Path]

    var editFriendsStore: EditFriendsStore?
    var settingsStore: SettingsStore?

    var currentUser: User? {
        guard let username = currentUsername else { return nil }
        return User(
            username: username,
            realName: nil,
            imageURL: nil,
            url: nil,
            playCount: nil
        )
    }

    var hasCurrentUser: Bool {
        guard let username = currentUsername else { return false }
        return !username.isEmpty
    }

    var hasFriends: Bool {
        !curatedFriends.isEmpty
    }

    init() {}

    func showEditSheet() {
        editFriendsStore = EditFriendsStore()
    }

    func showSettings() {
        settingsStore = SettingsStore()
    }

    func navigateToUser(_ user: User) {
        let weeklyAlbumsStore = WeeklyAlbumsStore(user: user, currentYearOffset: 1)
        $navigationPath.withLock { $0.append(.weeklyAlbums(weeklyAlbumsStore)) }
    }
}
