import Combine
import Sharing
import SwiftUI

struct EditFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.lastFMClient) private var lastFMClient

    // Use @Shared directly
    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = []

    @State private var friendsImporter: FriendsImporter?

    @State private var editableFriends: [User] = []
    @State private var selectedFriends: Set<String> = []
    @State private var showingAddFriend = false

    // Computed property for User object (for backward compatibility)
    private var currentUser: User? {
        guard let username = currentUsername else { return nil }
        return User(
            username: username,
            realName: nil,
            imageURL: nil,
            url: nil,
            playCount: nil
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Import section
                if currentUsername != nil {
                    VStack(spacing: 16) {
                        Button(action: importFriends) {
                            HStack {
                                if friendsImporter?.isLoading == true {
                                    AnimatedLoadingIndicator(size: 20)
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                }

                                Text(friendsImporter?.isLoading == true ? "Importing..." : "Import friends from Last.fm")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.accent)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(friendsImporter?.isLoading == true)

                        Button(action: { showingAddFriend = true }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Add friend manually")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.secondaryBackground)
                            .foregroundColor(.accent)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.primaryBackground)
                }

                Divider()

                // Friends list
                List {
                    if !editableFriends.isEmpty {
                        Section {
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
                            }
                            .onMove(perform: moveFriends)
                            .onDelete(perform: deleteFriends)
                        }
                    } else {
                        Section {
                            VStack(spacing: 16) {
                                Image(systemName: "person.2")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accent.opacity(0.6))

                                Text("No friends in your curated list")
                                    .font(.f(.medium, .body))
                                    .foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Edit Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFriends()
                    }
                    .fontWeight(.semibold)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button(selectedFriends.count == editableFriends.count ? "Select None" : "Select All") {
                        toggleSelectAll()
                    }
                    .disabled(editableFriends.isEmpty)

                    Spacer()

                    Button("Delete Selected (\(selectedFriends.count))") {
                        deleteSelectedFriends()
                    }
                    .disabled(selectedFriends.isEmpty)
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView { newFriend in
                    if !editableFriends.contains(where: { $0.username == newFriend.username }) {
                        editableFriends.append(newFriend)
                    }
                }
            }
        }
        .onAppear {
            editableFriends = curatedFriends
            selectedFriends = Set(curatedFriends.map(\.username))

            // Initialize friendsImporter with the environment client
            if friendsImporter == nil {
                friendsImporter = FriendsImporter(lastFMClient: lastFMClient)
            }
        }
        .onChange(of: friendsImporter?.friends) { _, importedFriends in
            if let importedFriends, !importedFriends.isEmpty {
                handleImportedFriends(importedFriends)
            }
        }
    }

    private func importFriends() {
        guard let username = currentUsername,
              let importer = friendsImporter else { return }

        Task {
            await importer.importFriends(for: username)
        }
    }

    private func handleImportedFriends(_ importedFriends: [User]) {
        guard let importer = friendsImporter else { return }
        let newFriends = importer.getNewFriends(excluding: editableFriends)

        if !newFriends.isEmpty {
            // Automatically add new friends without confirmation
            editableFriends.append(contentsOf: newFriends)
        }
    }

    private func moveFriends(from source: IndexSet, to destination: Int) {
        editableFriends.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteFriends(at offsets: IndexSet) {
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
        HStack(spacing: 12) {
            // Selection indicator
            Button(action: { onSelectionChanged(!isSelected) }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accent : .gray)
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())

            // User info
            Text(friend.username)
                .font(.f(.medium, .headline))
                .foregroundColor(.primaryText)

            Spacer()

            // Drag handle
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.gray)
                .font(.system(size: 16))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectionChanged(!isSelected)
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
                    Text("Enter Last.fm username")
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

                        Text(isValidating ? "Validating..." : "Add Friend")
                            .fontWeight(.semibold)
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
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func validateAndAdd() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a username"
            return
        }

        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        // Prevent user from adding themselves
        if cleanUsername.lowercased() == currentUsername?.lowercased() {
            errorMessage = "You cannot add yourself as a friend"
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
                username: username,
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
                errorMessage = "Username not found. Please check your spelling."
            case LastFMError.networkUnavailable:
                errorMessage = "No internet connection. Please try again."
            default:
                errorMessage = "Unable to validate username. Please try again."
            }
        }

        isValidating = false
    }
}

// MARK: - Previews

#Preview {
    EditFriendsView()
}
