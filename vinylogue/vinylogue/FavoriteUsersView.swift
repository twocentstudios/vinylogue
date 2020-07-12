import SwiftUI

struct FavoriteUsersListView: View {
    @State var me: String
    @State var friends: [String]

    var body: some View {
        List {
            Section(header: SimpleHeader("me")) {
                LargeSimpleCell(me)
            }
            Section(
                header: SimpleHeader("friends")
            ) {
                ForEach(friends, id: \.self) { friend in
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
            leading: Button {
                print("settings")
            } label: {
                Image("settings")
                    .renderingMode(.original)
            },
            trailing: EditButton()
        )
    }
}

struct FavoriteUsersListView_Previews: PreviewProvider {
    static let me = "ybsc"
    static let friends = ["BobbyStompy", "slippydrums", "esheikh"]
    static var previews: some View {
        Group {
            NavigationView {
                FavoriteUsersListView(me: me, friends: friends)
            }
            .preferredColorScheme(.dark)
            NavigationView {
                FavoriteUsersListView(me: me, friends: friends)
            }
        }
    }
}
