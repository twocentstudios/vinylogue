import ComposableArchitecture
import MessageUI
import SwiftUI

struct SettingsView: View {
    struct State: Equatable {
        let playCountFilter: String
    }

    let store: Store<SettingsState, SettingsAction>

    @SwiftUI.State private var isShowingMailView = false

    var body: some View {
        WithViewStore(store.scope { $0.view }) { viewStore in
            List {
                Section(header:
                    SimpleHeader("play count filter")
                ) {
                    Button(action: { viewStore.send(.updatePlayCountFilter) }) {
                        SimpleCell(viewStore.playCountFilter)
                    }
                }
                Section(header:
                    SimpleHeader("support")
                ) {
                    if MFMailComposeViewController.canSendMail() {
                        Button(action: { isShowingMailView = true }) {
                            SimpleCell("report an issue")
                        }
                    }
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
            .sheet(isPresented: $isShowingMailView) {
                // TODO: test mail on a real device
                MailView(result: Binding.constant(nil))
            }
        }
    }
}

// struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            NavigationView {
//                SettingsView()
//            }
//            NavigationView {
//                SettingsView()
//            }
//            .preferredColorScheme(.dark)
//        }
//    }
// }

extension SettingsState {
    var view: SettingsView.State {
        .init(playCountFilter: playCountString)
    }

    private var playCountString: String {
        switch user.settings.playCountFilter {
        case .off: return "off"
        case .p1: return "1 play"
        case .p2: return "2 plays"
        case .p4: return "4 plays"
        case .p8: return "8 plays"
        case .p16: return "16 plays"
        }
    }
}
