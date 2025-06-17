import Sharing
import SwiftUI

struct UsersListView: View {
    // Use @Shared directly
    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = []

    @State private var showingEditSheet = false
    @State private var showingSettingsSheet = false

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
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Current user section
                    if let username = currentUsername {
                        Section {
                            UserRowView(
                                user: currentUser ?? User(username: username, realName: nil, imageURL: nil, url: nil, playCount: nil),
                                isCurrentUser: true
                            )
                        } header: {
                            SectionHeaderView("me")
                        }
                    }

                    // Friends section
                    if !curatedFriends.isEmpty {
                        Section {
                            ForEach(curatedFriends, id: \.username) { friend in
                                UserRowView(user: friend, isCurrentUser: false)
                            }
                        } header: {
                            SectionHeaderView("friends")
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
                                        .font(.f(.medium, .headline))
                                        .foregroundColor(.primaryText)

                                    Text("Import friends from Last.fm or add them manually")
                                        .font(.f(.regular, .caption1))
                                        .foregroundColor(.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        }
                    }
                }
            }
            .navigationTitle("scrobblers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.f(.medium, .body))
                            .foregroundColor(.accent)
                    }
                }

                ToolbarItem(placement: .principal) {
                    // TODO: font style
                    Text("scrobblers")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditFriendsView()
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsSheet()
            }
            .background(Color.primaryBackground, ignoresSafeAreaEdges: .all)
        }
    }
}

// MARK: - User Row View

private struct UserRowView: View {
    let user: User
    let isCurrentUser: Bool

    var body: some View {
        NavigationLink(destination: WeeklyAlbumsView(user: user)) {
            Text(user.username)
                .padding(.horizontal, 24)
                .font(isCurrentUser ? .f(.regular, .largeTitle) : .f(.regular, .title2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, isCurrentUser ? 3 : 7)
                .contentShape(Rectangle())
        }
        .buttonStyle(UserRowButtonStyle())
    }
}

// MARK: - Previews

#Preview("With Friends") {
    UsersListView()
}

#Preview("Empty State") {
    UsersListView()
}

struct UserRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .white : .primaryText)
            .background {
                Rectangle().fill(Color.vinylogueBlueDark.opacity(configuration.isPressed ? 1.0 : 0.0))
            }
    }
}
