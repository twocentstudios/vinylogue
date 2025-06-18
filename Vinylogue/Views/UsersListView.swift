import Sharing
import SwiftUI

struct UsersListView: View {
    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = []

    @State private var showingEditSheet = false
    @State private var showingSettingsSheet = false

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

                    if !curatedFriends.isEmpty {
                        Section {
                            ForEach(curatedFriends, id: \.username) { friend in
                                UserRowView(user: friend, isCurrentUser: false)
                            }

                            EditFriendsButton {
                                showingEditSheet = true
                            }
                        } header: {
                            SectionHeaderView("friends")
                        }
                    }

                    if curatedFriends.isEmpty {
                        Section {
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accent)

                                VStack(spacing: 8) {
                                    Text("no friends added yet")
                                        .font(.f(.medium, .headline))
                                        .foregroundColor(.primaryText)

                                    Text("import friends from Last.fm or add them manually")
                                        .font(.f(.regular, .caption1))
                                        .foregroundColor(.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)

                            EditFriendsButton {
                                showingEditSheet = true
                            }
                        } header: {
                            SectionHeaderView("friends")
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
                    .sensoryFeedback(.impact, trigger: showingSettingsSheet)
                }

                ToolbarItem(placement: .principal) {
                    // TODO: font style
                    Text("scrobblers")
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
    @Previewable @Shared(.appStorage("currentUser")) var currentUsername: String? = "musiclover123"
    @Previewable @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = [
        User(username: "rockfan92", realName: "Alex Johnson", playCount: 15432),
        User(username: "jazzlover", realName: "Sarah Miller", playCount: 8901),
        User(username: "metalhead", realName: nil, playCount: 23456),
        User(username: "popstar_fan", realName: "Emma Davis", playCount: 5678),
        User(username: "classicalmusic", realName: "David Wilson", playCount: 12890),
    ]

    UsersListView()
}

#Preview("Empty State") {
    @Previewable @Shared(.appStorage("currentUser")) var currentUsername: String? = "newuser"
    @Previewable @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = []

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

// MARK: - Edit Friends Button

private struct EditFriendsButton: View {
    let action: () -> Void
    @State private var buttonPressed = false

    var body: some View {
        Button(action: {
            buttonPressed.toggle()
            action()
        }) {
            Text("edit friends")
                .font(.f(.ultralight, .headline))
                .foregroundColor(Color.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
        }
        .sensoryFeedback(.impact, trigger: buttonPressed)
        .buttonStyle(PlainButtonStyle())
    }
}
