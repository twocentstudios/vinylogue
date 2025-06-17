import Sharing
import SwiftUI

struct UsersListView: View {
    // Use @Shared directly
    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = []

    @StateObject private var friendsImporter = FriendsImporter(lastFMClient: LastFMClient())

    @State private var showingEditSheet = false
    @State private var showingImportAlert = false
    @State private var showingSettingsSheet = false
    @State private var importedFriendsCount = 0

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
            List {
                // Current user section
                if let username = currentUsername {
                    Section {
                        UserRowView(
                            user: currentUser ?? User(username: username, realName: nil, imageURL: nil, url: nil, playCount: nil),
                            isCurrentUser: true
                        )
                    } header: {
                        Text("me")
                            .font(.sectionHeader)
                            .foregroundColor(.tertiaryText)
                            .textCase(.lowercase)
                    }
                }

                // Friends section
                if !curatedFriends.isEmpty {
                    Section {
                        ForEach(curatedFriends, id: \.username) { friend in
                            UserRowView(user: friend, isCurrentUser: false)
                        }
                    } header: {
                        Text("friends")
                            .font(.sectionHeader)
                            .foregroundColor(.tertiaryText)
                            .textCase(.lowercase)
                    }
                }

                // Empty state for friends
                if curatedFriends.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.accent)

                            VStack(spacing: 8) {
                                Text("No friends added yet")
                                    .font(.usernameRegular)
                                    .foregroundColor(.primaryText)

                                Text("Import friends from Last.fm or add them manually")
                                    .font(.secondaryInfo)
                                    .foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle(currentUsername ?? "Vinylogue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.body)
                            .foregroundColor(.accent)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .font(.body)
                    .foregroundColor(.accent)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditFriendsView(friendsImporter: friendsImporter)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsSheet()
            }
            .alert("Friends Imported", isPresented: $showingImportAlert) {
                Button("OK") {}
            } message: {
                Text("Added \(importedFriendsCount) new friends to your list")
            }
        }
        .onReceive(friendsImporter.$friends) { importedFriends in
            // This will be handled by the EditFriendsView
        }
    }
}

// MARK: - User Row View

private struct UserRowView: View {
    let user: User
    let isCurrentUser: Bool

    var body: some View {
        NavigationLink(destination: WeeklyAlbumsView(user: user)) {
            HStack(spacing: 12) {
                // User avatar placeholder
                Circle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: isCurrentUser ? "person.fill" : "person")
                            .font(.system(size: 18))
                            .foregroundColor(.accent)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.username)
                        .font(.scaledTitle3())
                        .foregroundColor(.primaryText)

                    if let realName = user.realName, !realName.isEmpty {
                        Text(realName)
                            .font(.scaledCaption())
                            .foregroundColor(.secondaryText)
                    }
                }

                Spacer()

                if let playCount = user.playCount {
                    Text("\(playCount) plays")
                        .font(.secondaryInfo)
                        .foregroundColor(.tertiaryText)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Previews

#Preview("With Friends") {
    UsersListView()
}

#Preview("Empty State") {
    UsersListView()
}
