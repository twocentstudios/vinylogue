import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: AddFriendStore

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 10) {
                    Text("add friend")
                        .font(.f(.regular, .largeTitle))
                        .tracking(2)
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)

                    Text("enter last.fm username to add as friend")
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
                        accessibilityHint: "Enter a Last.fm username to add as friend",
                        onSubmit: {
                            Task { await store.validateAndAdd() }
                        }
                    )
                    .focused($isTextFieldFocused)

                    LoadingButton(
                        title: "add friend",
                        loadingTitle: "validating...",
                        isLoading: store.isValidating,
                        isDisabled: store.isAddButtonDisabled,
                        accessibilityLabel: store.accessibilityLabel,
                        accessibilityHint: "Validates the username and adds them as a friend",
                        action: {
                            Task {
                                await store.validateAndAdd()
                            }
                        }
                    )
                    .sensoryFeedback(.success, trigger: store.friendAdded)
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
        .onChange(of: store.friendAdded) { _, newValue in
            if newValue {
                dismiss()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .alert("Friend Validation", isPresented: $store.showError) {
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

#Preview {
    AddFriendView(store: AddFriendStore(onFriendAdded: { _ in }))
}
