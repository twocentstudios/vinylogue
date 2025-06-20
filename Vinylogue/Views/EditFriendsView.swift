import Combine
import Dependencies
import Sharing
import SwiftUI

struct EditFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: EditFriendsStore

    var body: some View {
        NavigationView {
            List {
                if store.currentUsername != nil {
                    Section {
                        ImportFriendsButton(
                            isLoading: store.isImportingFriends,
                            action: { Task { store.importFriends } }
                        )
                        .listRowBackground(Color.primaryBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())

                        AddFriendButton {
                            store.showAddFriend()
                        }
                        .listRowBackground(Color.primaryBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    } header: {
                        SectionHeaderView("add friends", topPadding: 20)
                            .listRowInsets(EdgeInsets())
                    }
                }

                Section {
                    if store.hasEditableFriends {
                        ForEach(store.editableFriends, id: \.username) { friend in
                            FriendEditRowView(
                                friend: friend,
                                isSelected: store.isFriendSelected(friend)
                            ) { _ in
                                store.toggleFriendSelection(friend)
                            }
                            .listRowBackground(Color.primaryBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        }
                        .onMove(perform: store.moveFriends)
                        .onDelete(perform: store.deleteFriends)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2")
                                .font(.system(size: 40))
                                .foregroundColor(.accent.opacity(0.6))

                            Text("no friends in your curated list")
                                .font(.f(.medium, .headline))
                                .foregroundColor(.primaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .listRowBackground(Color.primaryBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    }
                } header: {
                    SectionHeaderView("friends (hold & drag to reorder)", topPadding: 20)
                        .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .background(Color.primaryBackground)
            .navigationTitle("edit friends")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                }

                ToolbarItem(placement: .principal) {
                    Text("edit friends")
                        .foregroundStyle(Color.vinylogueBlueDark)
                        .font(.f(.regular, .headline))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save") {
                        store.saveFriends()
                        dismiss()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                    .sensoryFeedback(.success, trigger: store.curatedFriends)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button("select \(store.selectAllButtonText)") {
                        store.toggleSelectAll()
                    }
                    .contentTransition(.numericText())
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                    .disabled(!store.hasEditableFriends)
                    .sensoryFeedback(.selection, trigger: store.selectedFriends)

                    Spacer()

                    Button("delete selected (\(store.selectedCount))") {
                        store.deleteSelectedFriends()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.destructive)
                    .disabled(!store.hasSelectedFriends)
                    .sensoryFeedback(.warning, trigger: store.selectedCount)
                }
            }
            .sheet(isPresented: $store.showingAddFriend) {
                AddFriendView { newFriend in
                    store.addFriend(newFriend)
                }
            }
        }
        .onAppear {
            store.loadFriends()
        }
        .onChange(of: store.friendsImporter.friendsState) { _, friendsState in
            if case let .loaded(importedFriends) = friendsState {
                store.handleImportedFriends(importedFriends)
            }
        }
    }
}

// MARK: - Friend Edit Row View

private struct FriendEditRowView: View {
    let friend: User
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void

    var body: some View {
        Button(action: { onSelectionChanged(!isSelected) }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accent : .gray)
                    .font(.system(size: 20))

                Text(friend.username)
                    .font(.f(.regular, .title2))
                    .foregroundColor(.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Add Friend View

private struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.lastFMClient) private var lastFMClient

    @Shared(.currentUser) var currentUsername: String?

    let onFriendAdded: (User) -> Void

    @State private var username = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var friendAdded = false
    @State private var showError = false
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
                        username: $username,
                        isValidating: $isValidating,
                        accessibilityHint: "Enter a Last.fm username to add as friend",
                        onSubmit: validateAndAdd
                    )
                    .focused($isTextFieldFocused)

                    LoadingButton(
                        title: "add friend",
                        loadingTitle: "validating...",
                        isLoading: isValidating,
                        isDisabled: username.isEmpty,
                        accessibilityLabel: isValidating ? "Validating username" : "Add friend",
                        accessibilityHint: "Validates the username and adds them as a friend",
                        action: validateAndAdd
                    )
                    .sensoryFeedback(.success, trigger: friendAdded)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .alert("Friend Validation", isPresented: $showError) {
            Button("OK") {
                isTextFieldFocused = true
            }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func validateAndAdd() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("please enter a username")
            return
        }

        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanUsername.lowercased() == currentUsername?.lowercased() {
            setError("you cannot add yourself as a friend")
            return
        }

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
            let response: UserInfoResponse = try await lastFMClient.request(.userInfo(username: username))

            let newFriend = User(
                username: response.user.name, // Use Last.fm API capitalization
                realName: response.user.realname?.isEmpty == false ? response.user.realname : nil,
                imageURL: response.user.image?.last?.text,
                url: response.user.url,
                playCount: response.user.playcount != nil ? Int(response.user.playcount!) : nil
            )

            onFriendAdded(newFriend)
            friendAdded = true
            dismiss()

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

        isValidating = false
    }

    private func setError(_ message: String) {
        errorMessage = message
        showError = true

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Import and Add Friend Buttons

private struct ImportFriendsButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    AnimatedLoadingIndicator(size: 20)
                } else {
                    Image(systemName: "square.and.arrow.down")
                }

                Text(isLoading ? "importing..." : "import friends from last.fm")
                    .font(.f(.regular, .title2))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .sensoryFeedback(.impact, trigger: isLoading)
        .foregroundColor(.accent)
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

private struct AddFriendButton: View {
    let action: () -> Void
    @State private var buttonPressed = false

    var body: some View {
        Button(action: {
            buttonPressed.toggle()
            action()
        }) {
            HStack {
                Image(systemName: "person.badge.plus")

                Text("add friend manually")
                    .font(.f(.regular, .title2))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .sensoryFeedback(.impact, trigger: buttonPressed)
        .foregroundColor(.accent)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview {
    let store = EditFriendsStore()
    return EditFriendsView(store: store)
        .onAppear {
            store.$currentUsername.withLock { $0 = "musiclover123" }
            store.$curatedFriends.withLock { $0 = [
                User(username: "rockfan92", realName: "Alex Johnson", playCount: 15432),
                User(username: "jazzlover", realName: "Sarah Miller", playCount: 8901),
                User(username: "metalhead", realName: nil, playCount: 23456),
            ] }
            store.loadFriends()
        }
}
