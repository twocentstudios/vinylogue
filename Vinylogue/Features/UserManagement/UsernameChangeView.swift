import Dependencies
import Sharing
import SwiftUI

struct UsernameChangeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = UsernameChangeStore()

    @Shared(.currentUser) var currentUsername: String?

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text("change username")
                    .font(.f(.regular, .largeTitle))
                    .tracking(2)
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)

                VStack(spacing: 0) {
                    LastFMUsernameInputView(
                        username: $store.newUsername,
                        isValidating: $store.isValidating,
                        accessibilityHint: "Enter your Last.fm username to change",
                        onSubmit: {
                            Task { await validateAndSave() }
                        }
                    )
                    .focused($isTextFieldFocused)

                    LoadingButton(
                        title: "save username",
                        loadingTitle: "validating...",
                        isLoading: store.isValidating,
                        isDisabled: !store.canSave,
                        accessibilityLabel: store.isValidating ? "Validating username" : "Save username",
                        accessibilityHint: "Validates your username and updates the app",
                        action: {
                            Task { await validateAndSave() }
                        }
                    )
                    .sensoryFeedback(.success, trigger: currentUsername)
                }

                Spacer()
            }
            .background(Color.primaryBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                }
            }
        }
        .onAppear {
            store.prepareForEntry()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .alert("Username Validation", isPresented: $store.showError) {
            Button("OK") {
                isTextFieldFocused = true
            }
        } message: {
            if let errorMessage = store.validationError {
                Text(errorMessage)
            }
        }
    }

    private func validateAndSave() async {
        if await store.validateAndSave() {
            dismiss()
        }
    }
}

#Preview {
    UsernameChangeView()
}