import Dependencies
import Sharing
import SwiftUI

@MainActor
@Observable
final class OnboardingStore: Identifiable {
    @ObservationIgnored @Dependency(\.lastFMClient) private var lastFMClient
    @ObservationIgnored @SharedReader(.currentUser) var currentUsername: String?
    @ObservationIgnored @SharedReader(.curatedFriends) var curatedFriends: [User]

    var username = ""
    var isValidating = false
    var errorMessage: String?
    var showError = false

    @ObservationIgnored private var friendsImporter = FriendsImporter()

    var isSubmitButtonDisabled: Bool {
        username.isEmpty
    }

    var accessibilityLabel: String {
        isValidating ? "Validating username" : "Get started with Last.fm"
    }

    init() {}

    func validateAndSubmit() async {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("please enter a username")
            return
        }

        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        await validateUsername(cleanUsername)
    }

    private func validateUsername(_ username: String) async {
        isValidating = true
        errorMessage = nil
        showError = false

        do {
            let _: UserInfoResponse = try await lastFMClient.request(.userInfo(username: username))

            // Update global current user
            await MainActor.run {
                @Shared(.currentUser) var sharedCurrentUsername: String?
                $sharedCurrentUsername.withLock { $0 = username }
            }

            // Import friends for the user
            await friendsImporter.importFriends(for: username)

            // Update global curated friends if import was successful
            if case let .loaded(importedFriends) = friendsImporter.friendsState, !importedFriends.isEmpty {
                await MainActor.run {
                    @Shared(.curatedFriends) var sharedCuratedFriends: [User]
                    $sharedCuratedFriends.withLock { $0 = importedFriends }
                }
            }

            isValidating = false

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
        }
    }

    private func setError(_ message: String) {
        errorMessage = message
        showError = true

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    func dismissError() {
        // Error dismissed - focus will be handled by the view
    }
}
