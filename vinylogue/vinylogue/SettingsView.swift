import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            LazyVStack {
                Group {
                    SimpleHeader("play count filter")
                    SimpleCell("off")
                }
                Group {
                    SimpleHeader("support")
                    SimpleCell("report an issue")
                    SimpleCell("rate on appstore")
                    SimpleCell("licenses")
                }
                Group {
                    SimpleHeader("about")
                    SimpleCell("twocentstudios.com")
                    SimpleCell("@twocentstudios")
                }
                Group {
                    SimpleHeader("artist & album data")
                    SimpleCell("last.fm")
                }
            }
        }
        .navigationTitle("settings")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.whiteSubtle.edgesIgnoringSafeArea(.all))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}

private struct CellButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(!configuration.isPressed ? Color.blueDark : Color.whiteSubtle)
            .background(!configuration.isPressed ? Color.whiteSubtle : Color.blueDark)
    }
}
