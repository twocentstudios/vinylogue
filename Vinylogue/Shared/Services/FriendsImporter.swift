import Dependencies
import Foundation
import Observation
import OSLog

enum FriendsLoadingState: Equatable {
    case initialized
    case loading
    case loaded([User])
    case failed(EquatableError)
}

/// Service responsible for importing and managing friends from Last.fm
@Observable
@MainActor
final class FriendsImporter {
    @ObservationIgnored private let logger = Logger(subsystem: "com.twocentstudios.vinylogue", category: "FriendsImporter")
    @ObservationIgnored @Dependency(\.lastFMClient) private var lastFMClient

    /// Loading state for friends import
    var friendsState: FriendsLoadingState = .initialized

    init() {}

    /// Fetches friends list from Last.fm for the current user
    func importFriends(for username: String) async {
        friendsState = .loading

        logger.info("Starting friends import for user: \(username)")

        do {
            let response: UserFriendsResponse = try await lastFMClient.request(.userFriends(username: username))

            // Convert Last.fm friends to User objects and sort alphabetically by username
            let importedFriends = response.friends.user.map { friend in
                User(
                    username: friend.name,
                    realName: friend.realname?.isEmpty == false ? friend.realname : nil,
                    imageURL: friend.image?.last?.text, // Use largest image
                    url: friend.url,
                    playCount: friend.playcount != nil ? Int(friend.playcount!) : nil
                )
            }.sorted { $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending }

            friendsState = .loaded(importedFriends)
            logger.info("Successfully imported \(importedFriends.count) friends")

        } catch {
            logger.error("Failed to import friends: \(error.localizedDescription)")
            friendsState = .failed(error.toEquatableError())
        }
    }

    /// Gets friends that aren't already in the curated list, sorted alphabetically
    func getNewFriends(excluding curatedFriends: [User]) -> [User] {
        guard case let .loaded(friends) = friendsState else { return [] }

        let curatedUsernames = Set(curatedFriends.map { $0.username.lowercased() })
        return friends.filter { !curatedUsernames.contains($0.username.lowercased()) }
            .sorted { $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending }
    }

    /// Clears the current friends list and any errors
    func clearFriends() {
        friendsState = .initialized
        logger.info("Cleared friends list")
    }
}
