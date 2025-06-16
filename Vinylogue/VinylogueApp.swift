import Nuke
import SwiftUI

@main
struct VinylogueApp: App {
    @State private var lastFMClient = LastFMClient()
    @State private var imagePipeline = ImagePipeline.withTemporaryDiskCache()
    @State private var currentUser: User?
    @State private var playCountFilter: Int = 1

    init() {
        // Initialize current user from UserDefaults if available
        if let username = UserDefaults.standard.string(forKey: "currentUser") {
            _currentUser = State(initialValue: User(
                username: username,
                realName: nil,
                imageURL: nil,
                url: nil,
                playCount: nil
            ))
        }
        
        // Initialize play count filter
        let savedFilter = UserDefaults.standard.object(forKey: "currentPlayCountFilter") as? Int
        _playCountFilter = State(initialValue: savedFilter ?? 1)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.lastFMClient, lastFMClient)
                .environment(\.imagePipeline, imagePipeline)
                .environment(\.currentUser, currentUser)
                .environment(\.playCountFilter, playCountFilter)
        }
    }
}
