import SwiftUI

struct FavoriteUsersView: View {
    @State var me: String
    @State var friends: [String]

    var body: some View {
        ScrollView {
            // TODO: consider List for editing/reordering
            LazyVStack(pinnedViews: [.sectionHeaders]) {
                Section(header: SimpleHeader("me")) {
                    LargeSimpleCell(me)
                }
                Section(header: SimpleHeader("friends")) {
                    ForEach(friends, id: \.self) { friend in
                        SimpleCell(friend)
                    }
                }
            }
        }
        .navigationTitle("scrobblers")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button {
                print("settings")
            } label: {
                Image("settings")
                    .renderingMode(.original)
            },
            trailing: Button {
                print("edit")
            } label: {
                Text("Edit")
            }
        )
        .background(Color.whiteSubtle.edgesIgnoringSafeArea(.all))
    }
}

struct FavoriteUsersView_Previews: PreviewProvider {
    static let me = "ybsc"
    static let friends = ["BobbyStompy", "slippydrums", "esheikh"]
    static var previews: some View {
        NavigationView {
            FavoriteUsersView(me: me, friends: friends)
        }
    }
}
