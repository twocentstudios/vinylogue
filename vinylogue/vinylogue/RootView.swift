import ComposableArchitecture
import SwiftUI

struct RootView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            // TODO: using `switch` with a Store or ViewStore breaks the compiler

            if case .startup = viewStore.viewState {
                ProgressView()
                    .onAppear {
                        viewStore.send(.loadUserFromDisk)
                    }
            } else if case .login = viewStore.viewState {
                IfLetStore(store.scope(state: { $0.loginState }, action: AppAction.login)) {
                    LoginView(store: $0)
                }
            } else if case .favoriteUsers = viewStore.viewState {
                IfLetStore(store.scope(state: { $0.favoriteUsersState }, action: AppAction.favoriteUsers)) { store in
                    NavigationView {
                        FavoriteUsersListView(me: "TODO", friends: [])
//                        FavoriteUsersListView(me: store.state.user.me, friends: store.state.user.friends)
                    }
                }
            } else {
                fatalError()
            }
        }
//        NavigationView {
//            LoginView(userName: .constant(""))
//            FavoriteUsersListView(me: FavoriteUsersListView_Previews.me, friends: FavoriteUsersListView_Previews.friends)
//            WeeklyAlbumChartView(model: WeeklyAlbumChartView_Previews.mock)
//            AlbumDetailView(model: AlbumDetailView_Previews.mock)
//        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(
            store: Store(
                initialState: AppState(userState: UserState.uninitialized, viewState: .startup),
                reducer: appReducer,
                environment: .mockFirstTime
            ))
    }
}
