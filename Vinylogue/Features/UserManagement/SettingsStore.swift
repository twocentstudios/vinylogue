import Dependencies
import Sharing
import SwiftUI

@MainActor
@Observable
final class SettingsStore: Identifiable {
    @ObservationIgnored @Shared(.currentPlayCountFilter) var playCountFilter

    var usernameChangeStore: UsernameChangeStore?

    var playCountFilterString: String {
        switch playCountFilter {
        case 0:
            "off"
        case 1:
            "1 play"
        default:
            "\(playCountFilter) plays"
        }
    }

    init() {}

    func cyclePlayCountFilter() {
        $playCountFilter.withLock { filter in
            if filter > 31 {
                filter = 0
            } else if filter == 0 {
                filter = 1
            } else {
                filter *= 2
            }
        }
    }

    func showUsernameChange() {
        usernameChangeStore = UsernameChangeStore()
    }
}
