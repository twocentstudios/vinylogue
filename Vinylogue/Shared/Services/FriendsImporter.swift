import Dependencies
import Foundation
import Observation
import OSLog

/// Service responsible for importing and managing friends from Last.fm
@Observable
@MainActor
final class FriendsImporter {
    @ObservationIgnored private let logger = Logger(subsystem: "com.twocentstudios.vinylogue", category: "FriendsImporter")
    @ObservationIgnored @Dependency(\.lastFMClient) private var lastFMClient

    /// Current friends list loaded from Last.fm
    var friends: [User] = []

    /// Loading state for friends import
    var isLoading = false

    /// Any import error that occurred
    var importError: Error?

    init() {}

    /// Fetches friends list from Last.fm for the current user
    func importFriends(for username: String) async {
        isLoading = true
        importError = nil

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

            friends = importedFriends
            logger.info("Successfully imported \(importedFriends.count) friends")

        } catch {
            logger.error("Failed to import friends: \(error.localizedDescription)")
            importError = error
            friends = []
        }

        isLoading = false
    }

    /// Gets friends that aren't already in the curated list, sorted alphabetically
    func getNewFriends(excluding curatedFriends: [User]) -> [User] {
        let curatedUsernames = Set(curatedFriends.map { $0.username.lowercased() })
        return friends.filter { !curatedUsernames.contains($0.username.lowercased()) }
            .sorted { $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending }
    }

    /// Clears the current friends list and any errors
    func clearFriends() {
        friends = []
        importError = nil
        logger.info("Cleared friends list")
    }
}

// MARK: - Import Errors

enum FriendsImportError: LocalizedError {
    case noCurrentUser
    case importFailed(String)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            "No current user found. Please set up your Last.fm username first."
        case let .importFailed(message):
            "Failed to import friends: \(message)"
        case .networkUnavailable:
            "Network unavailable. Please check your connection and try again."
        }
    }
}
