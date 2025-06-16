import Foundation
import OSLog

/// Service responsible for importing and managing friends from Last.fm
@MainActor
final class FriendsImporter: ObservableObject {
    private let logger = Logger(subsystem: "com.twocentstudios.vinylogue", category: "FriendsImporter")
    private let lastFMClient: LastFMClientProtocol

    /// Current friends list loaded from Last.fm
    @Published var friends: [User] = []

    /// Loading state for friends import
    @Published var isLoading = false

    /// Any import error that occurred
    @Published var importError: Error?

    init(lastFMClient: LastFMClientProtocol) {
        self.lastFMClient = lastFMClient
    }

    /// Fetches friends list from Last.fm for the current user
    func importFriends(for username: String) async {
        isLoading = true
        importError = nil

        logger.info("Starting friends import for user: \(username)")

        do {
            let response: UserFriendsResponse = try await lastFMClient.request(.userFriends(username: username))

            // Convert Last.fm friends to User objects
            let importedFriends = response.friends.user.map { friend in
                User(
                    username: friend.name,
                    realName: friend.realname?.isEmpty == false ? friend.realname : nil,
                    imageURL: friend.image?.last?.text, // Use largest image
                    url: friend.url,
                    playCount: friend.playcount != nil ? Int(friend.playcount!) : nil
                )
            }

            friends = importedFriends
            logger.info("Successfully imported \(importedFriends.count) friends")

        } catch {
            logger.error("Failed to import friends: \(error.localizedDescription)")
            importError = error
            friends = []
        }

        isLoading = false
    }

    /// Gets friends that aren't already in the curated list
    func getNewFriends(excluding curatedFriends: [User]) -> [User] {
        let curatedUsernames = Set(curatedFriends.map(\.username))
        return friends.filter { !curatedUsernames.contains($0.username) }
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
