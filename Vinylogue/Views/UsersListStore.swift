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
    var navigationPath = NavigationPath()

    var editFriendsStore = EditFriendsStore()

    // Store instances for child views, keyed by username
    @ObservationIgnored private var weeklyAlbumsStores: [String: WeeklyAlbumsStore] = [:]

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

    // MARK: - Child Store Management

    func getWeeklyAlbumsStore(for user: User) -> WeeklyAlbumsStore {
        let key = user.username

        if let existingStore = weeklyAlbumsStores[key] {
            return existingStore
        }

        // Create new store - dependencies should propagate automatically
        let newStore = WeeklyAlbumsStore()

        weeklyAlbumsStores[key] = newStore
        return newStore
    }
}
