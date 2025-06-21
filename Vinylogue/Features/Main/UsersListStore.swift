import Dependencies
import Sharing
import SwiftUI

@MainActor
@Observable
final class UsersListStore {
    @ObservationIgnored @Shared(.currentUser) var currentUsername: String?
    @ObservationIgnored @Shared(.curatedFriends) var curatedFriends

    var showingEditSheet = false
    var showingSettingsSheet = false

    var editFriendsStore = EditFriendsStore()

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
        showingEditSheet = true
    }

    func hideEditSheet() {
        showingEditSheet = false
    }

    func showSettingsSheet() {
        showingSettingsSheet = true
    }

    func hideSettingsSheet() {
        showingSettingsSheet = false
    }
}
