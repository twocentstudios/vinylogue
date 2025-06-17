import Combine
import Sharing
import SwiftUI

struct EditFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.lastFMClient) private var lastFMClient

    // Use @Shared directly
    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = []

    @StateObject private var friendsImporter = FriendsImporter(lastFMClient: LastFMClient.shared)

    @State private var editableFriends: [User] = []
    @State private var selectedFriends: Set<String> = []
    @State private var showingAddFriend = false

    var body: some View {
        NavigationView {
            List {
                // Import buttons section
                if currentUsername != nil {
                    Section {
                        ImportFriendsButton(
                            isLoading: friendsImporter.isLoading,
                            action: importFriends
                        )
                        .listRowBackground(Color.primaryBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())

                        AddFriendButton {
                            showingAddFriend = true
                        }
                        .listRowBackground(Color.primaryBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    } header: {
                        SectionHeaderView("import", topPadding: 20)
                    }
                }

                // Friends list section
                Section {
                    if !editableFriends.isEmpty {
                        ForEach(editableFriends, id: \.username) { friend in
                            FriendEditRowView(
                                friend: friend,
                                isSelected: selectedFriends.contains(friend.username)
                            ) { isSelected in
                                if isSelected {
                                    selectedFriends.insert(friend.username)
                                } else {
                                    selectedFriends.remove(friend.username)
                                }
                            }
                            .listRowBackground(Color.primaryBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        }
                        .onMove(perform: moveFriends)
                        .onDelete(perform: deleteFriends)
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
                    SectionHeaderView("friends", topPadding: 20)
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
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save") {
                        saveFriends()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button("select \(selectedFriends.count == editableFriends.count ? "none" : "all")") {
                        toggleSelectAll()
                    }
                    .contentTransition(.numericText())
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                    .disabled(editableFriends.isEmpty)

                    Spacer()

                    Button("delete selected (\(selectedFriends.count))") {
                        deleteSelectedFriends()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.destructive)
                    .disabled(selectedFriends.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView { newFriend in
                    // Check for case-insensitive duplicates
                    if !editableFriends.contains(where: { $0.username.lowercased() == newFriend.username.lowercased() }) {
                        editableFriends.append(newFriend)
                    }
                }
            }
        }
        .onAppear {
            editableFriends = curatedFriends
            selectedFriends = Set(curatedFriends.map(\.username))

            friendsImporter.updateClient(lastFMClient)
        }
        .onChange(of: friendsImporter.friends) { _, importedFriends in
            if !importedFriends.isEmpty {
                handleImportedFriends(importedFriends)
            }
        }
    }

    private func importFriends() {
        guard let username = currentUsername else { return }

        Task {
            await friendsImporter.importFriends(for: username)
        }
    }

    private func handleImportedFriends(_ importedFriends: [User]) {
        let newFriends = friendsImporter.getNewFriends(excluding: editableFriends)

        if !newFriends.isEmpty {
            // Automatically add new friends without confirmation
            editableFriends.append(contentsOf: newFriends)
        }
    }

    private func moveFriends(from source: IndexSet, to destination: Int) {
        editableFriends.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteFriends(at offsets: IndexSet) {
        // Remove the deleted friends from selectedFriends
        for offset in offsets {
            let deletedFriend = editableFriends[offset]
            selectedFriends.remove(deletedFriend.username)
        }

        editableFriends.remove(atOffsets: offsets)
    }

    private func toggleSelectAll() {
        if selectedFriends.count == editableFriends.count {
            // Deselect all
            selectedFriends.removeAll()
        } else {
            // Select all
            selectedFriends = Set(editableFriends.map(\.username))
        }
    }

    private func deleteSelectedFriends() {
        editableFriends.removeAll { friend in
            selectedFriends.contains(friend.username)
        }
        selectedFriends.removeAll()
    }

    private func saveFriends() {
        // Persist curated friends using @Shared - automatic persistence
        $curatedFriends.withLock { $0 = editableFriends }
        dismiss()
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
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accent : .gray)
                    .font(.system(size: 20))

                // User info
                Text(friend.username)
                    .font(.f(.regular, .title2))
                    .foregroundColor(.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Add Friend View

private struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.lastFMClient) private var lastFMClient

    // Access current user to prevent self-adding
    @Shared(.appStorage("currentUser")) var currentUsername: String?

    let onFriendAdded: (User) -> Void

    @State private var username = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("enter last.fm username")
                        .font(.f(.ultralight, .headline))
                        .foregroundColor(.primaryText)

                    TextField("username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isTextFieldFocused)
                        .onSubmit(validateAndAdd)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.f(.regular, .caption1))
                            .foregroundColor(.destructive)
                    }
                }

                Button(action: validateAndAdd) {
                    HStack {
                        if isValidating {
                            AnimatedLoadingIndicator(size: 20)
                        }

                        Text(isValidating ? "validating..." : "add friend")
                            .font(.f(.medium, .body))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(username.isEmpty || isValidating ? Color.gray.opacity(0.6) : Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(username.isEmpty || isValidating)

                Spacer()
            }
            .padding()
            .navigationTitle("add friend")
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
                    Text("add friend")
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func validateAndAdd() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "please enter a username"
            return
        }

        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        // Prevent user from adding themselves
        if cleanUsername.lowercased() == currentUsername?.lowercased() {
            errorMessage = "you cannot add yourself as a friend"
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
            dismiss()

        } catch {
            switch error {
            case LastFMError.userNotFound:
                errorMessage = "username not found. please check your spelling."
            case LastFMError.networkUnavailable:
                errorMessage = "no internet connection. please try again."
            default:
                errorMessage = "unable to validate username. please try again."
            }
        }

        isValidating = false
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
        .foregroundColor(.accent)
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

private struct AddFriendButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        .foregroundColor(.accent)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview {
    @Previewable @Shared(.appStorage("currentUser")) var currentUsername: String? = "musiclover123"
    @Previewable @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = [
        User(username: "rockfan92", realName: "Alex Johnson", playCount: 15432),
        User(username: "jazzlover", realName: "Sarah Miller", playCount: 8901),
        User(username: "metalhead", realName: nil, playCount: 23456),
    ]

    EditFriendsView()
}
