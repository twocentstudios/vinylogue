import Dependencies
import Nuke
import Sharing
import SwiftUI

@main
struct VinylogueApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    #if DEBUG
                        @Dependency(\.cacheManager) var cacheManager
                        try! await cacheManager.clearCache()
                    #endif
                }
        }
    }
}
