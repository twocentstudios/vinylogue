import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section(header:
                SimpleHeader("play count filter")
            ) {
                SimpleCell("off")
            }
            Section(header:
                SimpleHeader("support")
            ) {
                SimpleCell("report an issue")
                SimpleCell("rate on appstore")
                SimpleCell("licenses")
            }
            Section(header:
                SimpleHeader("about")
            ) {
                SimpleCell("twocentstudios.com")
                SimpleCell("@twocentstudios")
            }
            Section(header:
                SimpleHeader("artist & album data")
            ) {
                SimpleCell("last.fm")
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                SettingsView()
            }
            NavigationView {
                SettingsView()
            }
            .preferredColorScheme(.dark)
        }
    }
}
