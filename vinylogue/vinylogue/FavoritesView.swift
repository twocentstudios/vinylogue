import SwiftUI

struct FavoritesView: View {
    @State var me: String
    @State var friends: [String]

    var body: some View {
        VStack {
            Header(label: "me")
            Button {} label: {
                HStack {
                    Text(me)
                        .font(.avnRegular(34))
                        .padding(.leading, 20)
                    Spacer()
                }
            }
            .buttonStyle(CellButtonStyle())
            Header(label: "friends")
            ForEach(friends, id: \.self) { friend in
                Button {} label: {
                    HStack {
                        Text(friend)
                            .font(.avnRegular(24))
                            .padding(.leading, 20)
                            .padding(.vertical, 6)
                        Spacer()
                    }
                }
                .buttonStyle(CellButtonStyle())
            }
            Spacer()
        }
        .background(Color.whiteSubtle.edgesIgnoringSafeArea(.all))
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static let me = "ybsc"
    static let friends = ["BobbyStompy", "slippydrums", "esheikh"]
    static var previews: some View {
        FavoritesView(me: me, friends: friends)
    }
}

private struct CellButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(!configuration.isPressed ? Color.blueDark : Color.whiteSubtle)
            .background(!configuration.isPressed ? Color.whiteSubtle : Color.blueDark)
    }
}

private struct Header: View {
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(.avnUltraLight(17))
                .foregroundColor(.blueDark)
                .padding(.leading, 20)
                .padding(.top, 20)
            Spacer()
        }
    }
}
