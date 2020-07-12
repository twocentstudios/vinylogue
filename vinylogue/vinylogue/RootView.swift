import ComposableArchitecture
import SwiftUI

struct RootView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            // TODO: using `switch` with a Store or ViewStore breaks the compiler
            if case .uninitialized = viewStore.userState {
                ProgressView()
                    .onAppear {
                        viewStore.send(.loadUserFromDisk)
                    }
            } else if case .loggedOut = viewStore.userState {
                LoginView(store: store.scope(state: { $0.userState }, action: AppAction.login))
            } else if case let .loggedIn(user) = viewStore.userState {
                NavigationView {
                    FavoriteUsersListView(me: user.me, friends: user.friends)
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
                initialState: AppState(userState: UserState.uninitialized),
                reducer: appReducer,
                environment: .mockFirstTime
            ))
    }
}
