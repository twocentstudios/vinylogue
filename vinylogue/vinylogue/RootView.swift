import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationView {
            FavoriteUsersListView(me: FavoriteUsersListView_Previews.me, friends: FavoriteUsersListView_Previews.friends)
        }
//        LoginView(userName: .constant(""))
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
