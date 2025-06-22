import Dependencies
import Sharing
import SwiftUI

@MainActor
@Observable
final class UsernameChangeStore: Identifiable {
    @ObservationIgnored @Shared(.currentUser) var currentUsername: String?
    @ObservationIgnored @Shared(.curatedFriends) var curatedFriends
    @ObservationIgnored @Dependency(\.lastFMClient) var lastFMClient

    var newUsername = ""
    var isValidating = false
    var validationError: String?
    var isValid = false
    var showError = false

    var canSave: Bool {
        !newUsername.isEmpty && newUsername != currentUsername
    }

    init() {}

    func prepareForEntry() {
        newUsername = currentUsername ?? ""
        isValid = false
        validationError = nil
        showError = false
    }

    func validateAndSave() async -> Bool {
        guard canSave else { return false }
        guard !newUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("please enter a username")
            return false
        }

        let cleanUsername = newUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        return await validateUsername(cleanUsername)
    }

    private func validateUsername(_ username: String) async -> Bool {
        isValidating = true
        validationError = nil
        showError = false

        do {
            let _: UserInfoResponse = try await lastFMClient.request(.userInfo(username: username))
            isValid = true
            validationError = nil
            isValidating = false
            saveUsername()
            return true
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

            return false
        }
    }

    private func setError(_ message: String) {
        validationError = message
        showError = true

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func saveUsername() {
        $currentUsername.withLock { $0 = newUsername }
        $curatedFriends.withLock { $0 = [] }
    }
}
