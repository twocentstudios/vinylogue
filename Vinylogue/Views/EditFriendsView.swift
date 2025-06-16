import SwiftUI

struct EditFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.currentUser) private var currentUser
    @Environment(\.curatedFriends) private var curatedFriends
    @Environment(\.lastFMClient) private var lastFMClient

    @ObservedObject var friendsImporter: FriendsImporter

    @State private var editableFriends: [User] = []
    @State private var selectedFriends: Set<String> = []
    @State private var showingAddFriend = false
    @State private var showingImportConfirmation = false
    @State private var newFriendsToAdd: [User] = []

    private var currentUsername: String? {
        currentUser?.username ?? UserDefaults.standard.string(forKey: "currentUser")
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Import section
                if let username = currentUsername {
                    VStack(spacing: 16) {
                        Button(action: importFriends) {
                            HStack {
                                if friendsImporter.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                }

                                Text(friendsImporter.isLoading ? "Importing..." : "Import friends from Last.fm")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.accent)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(friendsImporter.isLoading)

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
                        } header: {
                            Text("Curated Friends")
                                .font(.sectionHeader)
                                .foregroundColor(.tertiaryText)
                        } footer: {
                            if !editableFriends.isEmpty {
                                Text("Drag to reorder • Swipe to delete • Tap to select/deselect")
                                    .font(.secondaryInfo)
                                    .foregroundColor(.tertiaryText)
                            }
                        }
                    } else {
                        Section {
                            VStack(spacing: 16) {
                                Image(systemName: "person.2")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accent.opacity(0.6))

                                Text("No friends in your curated list")
                                    .font(.body)
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
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView { newFriend in
                    if !editableFriends.contains(where: { $0.username == newFriend.username }) {
                        editableFriends.append(newFriend)
                    }
                }
            }
            .alert("Import Friends", isPresented: $showingImportConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Add \(newFriendsToAdd.count) friends") {
                    editableFriends.append(contentsOf: newFriendsToAdd)
                    newFriendsToAdd.removeAll()
                }
            } message: {
                Text("Found \(newFriendsToAdd.count) new friends to add to your curated list.")
            }
        }
        .onAppear {
            editableFriends = curatedFriends
            selectedFriends = Set(curatedFriends.map(\.username))
        }
        .onReceive(friendsImporter.$friends) { importedFriends in
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
            newFriendsToAdd = newFriends
            showingImportConfirmation = true
        }
    }

    private func moveFriends(from source: IndexSet, to destination: Int) {
        editableFriends.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteFriends(at offsets: IndexSet) {
        editableFriends.remove(atOffsets: offsets)
    }

    private func saveFriends() {
        // TODO: Persist to @Shared storage
        // For now, we'll update UserDefaults
        saveFriendsToUserDefaults()
        dismiss()
    }

    private func saveFriendsToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(editableFriends)
            UserDefaults.standard.set(data, forKey: "curatedFriends")
        } catch {
            print("Failed to save curated friends: \(error)")
        }
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
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.username)
                    .font(.usernameRegular)
                    .foregroundColor(.primaryText)

                if let realName = friend.realName, !realName.isEmpty {
                    Text(realName)
                        .font(.secondaryInfo)
                        .foregroundColor(.secondaryText)
                }
            }

            Spacer()

            // Play count
            if let playCount = friend.playCount {
                Text("\(playCount)")
                    .font(.secondaryInfo)
                    .foregroundColor(.tertiaryText)
            }

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
                        .font(.sectionHeader)
                        .foregroundColor(.primaryText)

                    TextField("username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isTextFieldFocused)
                        .onSubmit(validateAndAdd)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.secondaryInfo)
                            .foregroundColor(.destructive)
                    }
                }

                Button(action: validateAndAdd) {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
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
    EditFriendsView(friendsImporter: FriendsImporter(lastFMClient: LastFMClient()))
        .environment(\.curatedFriends, [
            User(username: "BobbyStompy", realName: "Bobby", imageURL: nil, url: nil, playCount: 2000),
            User(username: "slippydrums", realName: nil, imageURL: nil, url: nil, playCount: 1200),
        ])
}
