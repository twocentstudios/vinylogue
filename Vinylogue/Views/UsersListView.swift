import Sharing
import SwiftUI

struct UsersListView: View {
    @Bindable var store: UsersListStore

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let username = store.currentUsername {
                        Section {
                            UserRowView(
                                user: store.currentUser ?? User(username: username, realName: nil, imageURL: nil, url: nil, playCount: nil),
                                isCurrentUser: true
                            )
                        } header: {
                            SectionHeaderView("me")
                        }
                    }

                    if store.hasFriends {
                        Section {
                            ForEach(store.curatedFriends, id: \.username) { friend in
                                UserRowView(user: friend, isCurrentUser: false)
                            }
                        } header: {
                            FriendsHeaderView {
                                store.showEditSheet()
                            }
                        }
                    }

                    if !store.hasFriends {
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
                                        .foregroundColor(.primaryText)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } header: {
                            FriendsHeaderView {
                                store.showEditSheet()
                            }
                        }
                    }
                }
            }
            .navigationTitle("scrobblers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        store.showSettingsSheet()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.f(.ultralight, .body))
                            .foregroundColor(.accent)
                    }
                    .sensoryFeedback(.impact, trigger: store.showingSettingsSheet)
                }

                ToolbarItem(placement: .principal) {
                    Text("scrobblers")
                        .foregroundStyle(Color.vinylogueBlueDark)
                        .font(.f(.regular, .headline))
                }
            }
            .sheet(isPresented: $store.showingEditSheet) {
                EditFriendsView(store: store.editFriendsStore)
            }
            .sheet(isPresented: $store.showingSettingsSheet) {
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
    let store = UsersListStore()
    return UsersListView(store: store)
        .onAppear {
            store.$currentUsername.withLock { $0 = "musiclover123" }
            store.$curatedFriends.withLock { $0 = [
                User(username: "rockfan92", realName: "Alex Johnson", playCount: 15432),
                User(username: "jazzlover", realName: "Sarah Miller", playCount: 8901),
                User(username: "metalhead", realName: nil, playCount: 23456),
                User(username: "popstar_fan", realName: "Emma Davis", playCount: 5678),
                User(username: "classicalmusic", realName: "David Wilson", playCount: 12890),
            ] }
        }
}

#Preview("Empty State") {
    let store = UsersListStore()
    return UsersListView(store: store)
        .onAppear {
            store.$currentUsername.withLock { $0 = "newuser" }
            store.$curatedFriends.withLock { $0 = [] }
        }
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

// MARK: - Friends Header View

private struct FriendsHeaderView: View {
    let action: () -> Void
    @State private var buttonPressed = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("friends")
                .font(.f(.ultralight, .headline))
                .foregroundColor(.primaryText)
                .textCase(.lowercase)

            Spacer()

            Button(action: {
                buttonPressed.toggle()
                action()
            }) {
                Text("edit")
                    .font(.f(.ultralight, .headline))
                    .foregroundColor(Color.accent)
                    .contentShape(Rectangle())
            }
            .sensoryFeedback(.impact, trigger: buttonPressed)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
        .padding(.bottom, 0)
        .padding(.horizontal, 24)
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
            Text("edit")
                .font(.f(.ultralight, .headline))
                .foregroundColor(Color.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
        }
        .sensoryFeedback(.impact, trigger: buttonPressed)
        .buttonStyle(.plain)
    }
}
