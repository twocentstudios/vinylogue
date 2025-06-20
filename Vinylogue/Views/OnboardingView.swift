import Dependencies
import Sharing
import SwiftUI

struct OnboardingView: View {
    @Dependency(\.lastFMClient) private var lastFMClient

    @Shared(.currentUser) var currentUsername: String?
    @Shared(.curatedFriends) var curatedFriends

    @State private var username = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var showError = false

    @FocusState private var isTextFieldFocused: Bool

    @State private var friendsImporter = FriendsImporter()

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 10) {
                    Text("vinylogue")
                        .font(.f(.regular, .largeTitle))
                        .tracking(2)
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)

                    Text("what were you listening to this week last year?")
                        .font(.f(.ultralight, .title3))
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal)
                }
                .padding(.top, 40)

                VStack(spacing: 0) {
                    LastFMUsernameInputView(
                        username: $username,
                        isValidating: $isValidating,
                        errorMessage: errorMessage,
                        showError: showError,
                        accessibilityHint: "Enter your Last.fm username to get started",
                        onSubmit: validateAndSubmit
                    )
                    .focused($isTextFieldFocused)

                    LoadingButton(
                        title: "get started",
                        loadingTitle: "validating...",
                        isLoading: isValidating,
                        isDisabled: username.isEmpty,
                        accessibilityLabel: isValidating ? "Validating username" : "Get started with Last.fm",
                        accessibilityHint: "Validates your username and sets up the app",
                        action: validateAndSubmit
                    )
                    .sensoryFeedback(.success, trigger: currentUsername)
                }

                Spacer()
            }
            .background(Color.primaryBackground)
            .navigationBarHidden(true)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .alert("Username Validation", isPresented: $showError) {
            Button("OK") {
                isTextFieldFocused = true
            }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func validateAndSubmit() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("please enter a username")
            return
        }

        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            await validateUsername(cleanUsername)
        }
    }

    @MainActor
    private func validateUsername(_ username: String) async {
        isValidating = true
        errorMessage = nil
        showError = false

        do {
            let _: UserInfoResponse = try await lastFMClient.request(.userInfo(username: username))

            $currentUsername.withLock { $0 = username }

            await friendsImporter.importFriends(for: username)

            if case let .loaded(importedFriends) = friendsImporter.friendsState, !importedFriends.isEmpty {
                $curatedFriends.withLock { $0 = importedFriends }
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
}

// MARK: - Previews

#Preview("Default") {
    OnboardingView()
}

#Preview("Dark Mode") {
    OnboardingView()
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    OnboardingView()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}
