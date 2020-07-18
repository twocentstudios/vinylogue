import ComposableArchitecture
import SwiftUI

struct FavoriteUsersListView: View {
    struct State: Equatable {
        let me: String
        let friends: [String]
        let isSettingsActive: Bool
        // TODO: add friends button / loading
    }

    let store: Store<FavoriteUsersState, FavoriteUsersAction>

    var body: some View {
        WithViewStore(self.store.scope(state: \.view)) { viewStore in
            List {
                Section(header: SimpleHeader("me")) {
                    LargeSimpleCell(viewStore.me)
                }
                Section(
                    header: SimpleHeader("friends")
                ) {
                    ForEach(viewStore.friends, id: \.self) { friend in
                        SimpleCell(friend)
                    }
                    .onDelete { indexSet in
                        print(indexSet)
                    }
                    .onMove { indecies, newOffset in
                        print(indecies)
                    }
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
                        send: FavoriteUsersAction.setSettings(isActive:)
                    )
                ) {
                    Image("settings")
                        .renderingMode(.original)
                },
                trailing: EditButton()
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
    var view: FavoriteUsersListView.State {
        .init(
            me: user.me,
            friends: user.friends,
            isSettingsActive: settingsState != nil
        )
    }
}
