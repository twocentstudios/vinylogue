import Dependencies
import Sharing
import SwiftUI

struct OnboardingView: View {
    @Dependency(\.lastFMClient) private var lastFMClient

    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = []

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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("a last.fm username")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.f(.ultralight, .headline))
                            .foregroundColor(.primaryText)
                            .padding(.horizontal)
                            .padding(.bottom, 0)

                        HStack(spacing: 0) {
                            Image(systemName: "music.note")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .foregroundStyle(Color.vinylogueGray)
                            TextField("username", text: $username)
                                .foregroundStyle(Color.primaryText)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.never)
                                .minimumScaleFactor(0.7)
                                .autocorrectionDisabled()
                                .textContentType(.username)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if !username.isEmpty {
                                Button(action: { username = "" }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .font(.f(.demiBold, 40))
                                        .foregroundStyle(Color.primaryText.opacity(0.3))
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        .font(.f(.demiBold, 60))
                        .background {
                            Color.vinylogueGray.opacity(0.4)
                        }
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            validateAndSubmit()
                        }
                        .accessibilityLabel("Last.fm username")
                        .accessibilityHint("Enter your Last.fm username to get started")
                        .padding(.bottom, 16)

                        if let errorMessage, showError {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundColor(.destructive)
                                .font(.f(.regular, .caption1))
                                .padding(.horizontal)
                        }
                    }

                    Button(action: validateAndSubmit) {
                        HStack {
                            if isValidating {
                                AnimatedLoadingIndicator(size: 20)
                            }

                            Text(isValidating ? "validating..." : "get started")
                                .font(.f(.regular, .body))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(submitButtonBackground)
                        .foregroundColor(isValidating ? .primaryText.opacity(0.6) : .vinylogueWhiteSubtle)
                    }
                    .disabled(username.isEmpty || isValidating)
                    .sensoryFeedback(.success, trigger: currentUsername)
                    .accessibilityLabel(isValidating ? "Validating username" : "Get started with Last.fm")
                    .accessibilityHint("Validates your username and sets up the app")
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

    private var submitButtonBackground: Color {
        if username.isEmpty || isValidating {
            .vinylogueGray
        } else {
            .accent
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
