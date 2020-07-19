import ComposableArchitecture
import SwiftUI

struct FavoriteUsersListView: View {
    struct Model: Equatable {
        let me: Username
        let friends: [Username]
        let isSettingsActive: Bool
        let isWeeklyAlbumChartActive: Bool
        let weeklyAlbumChartViewUsername: Username?
        let isLogoutButtonActive: Bool
        let isEditingFriends: Bool
        let editMode: EditMode
        // TODO: add friends button / loading
    }

    let store: Store<FavoriteUsersState, FavoriteUsersAction>

    var body: some View {
        WithViewStore(self.store.scope(state: \.view)) { viewStore in
            List {
                Section(header: SimpleHeader("me")) {
                    if viewStore.isLogoutButtonActive {
                        Button(action: { viewStore.send(.logOut) }) {
                            // TODO: this button only extends to the width of the text
                            LargeSimpleCell("log out")
                                .foregroundColor(Color(.systemRed))
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        NavigationLink(
                            destination: IfLetStore(
                                self.store.scope(
                                    state: \.weeklyAlbumChartState,
                                    action: FavoriteUsersAction.weeklyAlbumChart
                                ),
                                then: WeeklyAlbumChartView.init(store:)
                            ),
                            isActive: viewStore.binding(
                                get: { $0.weeklyAlbumChartViewUsername == $0.me },
                                send: FavoriteUsersAction.setMeWeeklyAlbumChartView(isActive:)
                            )
                        ) {
                            LargeSimpleCell(viewStore.me)
                        }
                    }
                }
                Section(
                    header: SimpleHeader("friends")
                ) {
                    ForEach(viewStore.friends, id: \.self) { friend in
                        NavigationLink(
                            destination: IfLetStore(
                                self.store.scope(
                                    state: \.weeklyAlbumChartState,
                                    action: FavoriteUsersAction.weeklyAlbumChart
                                ),
                                then: WeeklyAlbumChartView.init(store:)
                            ),
                            isActive: viewStore.binding(
                                get: { $0.weeklyAlbumChartViewUsername == friend },
                                send: { FavoriteUsersAction.setFriendWeeklyAlbumChartView(isActive: $0, username: friend) }
                            )
                        ) {
                            SimpleCell(friend)
                        }
                        .disabled(viewStore.isEditingFriends)
                    }
                    .onDelete { viewStore.send(.deleteFriend($0)) }
                    .onMove { viewStore.send(.moveFriend($0, $1)) }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("scrobblers")
            .navigationBarItems(
                leading: NavigationLink(
                    destination: IfLetStore(
                        self.store.scope(
                            state: \.settingsState,
                            action: FavoriteUsersAction.settings
                        ),
                        then: SettingsView.init(store:)
                    ),
                    isActive: viewStore.binding(
                        get: \.isSettingsActive,
                        send: FavoriteUsersAction.setSettingsView(isActive:)
                    )
                ) {
                    Image("settings")
                        .renderingMode(.original)
                },
                trailing: EditButton()
            )
            .environment(
                \.editMode,
                viewStore.binding(get: { $0.editMode }, send: FavoriteUsersAction.editModeChanged)
            )
        }
    }
}

struct FavoriteUsersListView_Previews: PreviewProvider {
    static let me = "ybsc"
    static let friends = ["BobbyStompy", "slippydrums", "esheikh"]
    static var store: Store<FavoriteUsersState, FavoriteUsersAction> = {
        Store(
            initialState: FavoriteUsersState(user: .mock),
            reducer: favoriteUsersReducer,
            environment: .mockFirstTime
        )
    }()
    static var previews: some View {
        Group {
            NavigationView {
                FavoriteUsersListView(store: store)
            }
            .preferredColorScheme(.dark)
            NavigationView {
                FavoriteUsersListView(store: store)
            }
        }
    }
}

extension FavoriteUsersState {
    var view: FavoriteUsersListView.Model {
        .init(
            me: user.me,
            friends: user.friends,
            isSettingsActive: settingsState != nil,
            isWeeklyAlbumChartActive: weeklyAlbumChartState != nil,
            weeklyAlbumChartViewUsername: weeklyAlbumChartState?.username,
            isLogoutButtonActive: editMode == .active,
            isEditingFriends: editMode != .inactive,
            editMode: editMode
        )
    }
}
