import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationView {
            LoginView(userName: .constant(""))
//            FavoriteUsersListView(me: FavoriteUsersListView_Previews.me, friends: FavoriteUsersListView_Previews.friends)
//            WeeklyAlbumChartView(model: WeeklyAlbumChartView_Previews.mock)
//            AlbumDetailView(model: AlbumDetailView_Previews.mock)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
