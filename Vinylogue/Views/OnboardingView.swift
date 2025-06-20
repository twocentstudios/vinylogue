import Dependencies
import Sharing
import SwiftUI

struct OnboardingView: View {
    @Shared(.currentUser) var currentUsername: String?

    @State private var store = OnboardingStore()
    @FocusState private var isTextFieldFocused: Bool

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
                        username: $store.username,
                        isValidating: $store.isValidating,
                        errorMessage: store.errorMessage,
                        showError: store.showError,
                        accessibilityHint: "Enter your Last.fm username to get started",
                        onSubmit: {
                            Task {
                                await store.validateAndSubmit()
                            }
                        }
                    )
                    .focused($isTextFieldFocused)

                    LoadingButton(
                        title: "get started",
                        loadingTitle: "validating...",
                        isLoading: store.isValidating,
                        isDisabled: store.isSubmitButtonDisabled,
                        accessibilityLabel: store.accessibilityLabel,
                        accessibilityHint: "Validates your username and sets up the app",
                        action: {
                            Task {
                                await store.validateAndSubmit()
                            }
                        }
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
        .alert("Username Validation", isPresented: $store.showError) {
            Button("OK") {
                store.dismissError()
                isTextFieldFocused = true
            }
        } message: {
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
            }
        }
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
