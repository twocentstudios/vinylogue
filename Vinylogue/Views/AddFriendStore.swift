import Dependencies
import Sharing
import SwiftUI

@MainActor
@Observable
final class AddFriendStore {
    @ObservationIgnored @SharedReader(.currentUser) var currentUsername: String?
    @ObservationIgnored @Dependency(\.lastFMClient) var lastFMClient

    var username = ""
    var isValidating = false
    var errorMessage: String?
    var friendAdded = false
    var showError = false

    var isAddButtonDisabled: Bool {
        username.isEmpty
    }

    var accessibilityLabel: String {
        isValidating ? "Validating username" : "Add friend"
    }

    init() {}

    func validateAndAdd() async -> User? {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("please enter a username")
            return nil
        }

        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanUsername.lowercased() == currentUsername?.lowercased() {
            setError("you cannot add yourself as a friend")
            return nil
        }

        return await validateUsername(cleanUsername)
    }

    func validateUsername(_ username: String) async -> User? {
        isValidating = true
        errorMessage = nil
        showError = false

        do {
            let response: UserInfoResponse = try await lastFMClient.request(.userInfo(username: username))

            let newFriend = User(
                username: response.user.name, // Use Last.fm API capitalization
                realName: response.user.realname?.isEmpty == false ? response.user.realname : nil,
                imageURL: response.user.image?.last?.text,
                url: response.user.url,
                playCount: response.user.playcount != nil ? Int(response.user.playcount!) : nil
            )

            friendAdded = true
            isValidating = false
            return newFriend

        } catch {
            isValidating = false

            switch error {
            case LastFMError.userNotFound:
                setError("Username not found. Please check your spelling or create a Last.fm account.")
            case LastFMError.networkUnavailable:
                setError("No internet connection. Please check your network and try again.")
            case LastFMError.serviceUnavailable:
                setError("Last.fm is temporarily unavailable. Please try again later.")
            case LastFMError.invalidAPIKey:
                setError("There's an issue with the app configuration. Please contact support.")
            default:
                setError("Unable to validate username. Please try again.")
            }

            return nil
        }
    }

    func setError(_ message: String) {
        errorMessage = message
        showError = true

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    func dismissError() {
        // Error dismissed - focus will be handled by the view
    }
}
