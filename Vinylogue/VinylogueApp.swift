import Nuke
import SwiftUI

@main
struct VinylogueApp: App {
    @State private var lastFMClient = LastFMClient()
    @State private var imagePipeline = ImagePipeline.withTemporaryDiskCache()
    @State private var currentUser: User?
    @State private var playCountFilter: Int = 1
    @State private var curatedFriends: [User] = []

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

        // Initialize curated friends from UserDefaults
        if let friendsData = UserDefaults.standard.data(forKey: "curatedFriends") {
            do {
                let friends = try JSONDecoder().decode([User].self, from: friendsData)
                _curatedFriends = State(initialValue: friends)
            } catch {
                print("Failed to load curated friends: \(error)")
                _curatedFriends = State(initialValue: [])
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.lastFMClient, lastFMClient)
                .environment(\.imagePipeline, imagePipeline)
                .environment(\.currentUser, currentUser)
                .environment(\.playCountFilter, playCountFilter)
                .environment(\.curatedFriends, curatedFriends)
                .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                    // Update curated friends when UserDefaults changes
                    if let friendsData = UserDefaults.standard.data(forKey: "curatedFriends") {
                        do {
                            let friends = try JSONDecoder().decode([User].self, from: friendsData)
                            curatedFriends = friends
                        } catch {
                            print("Failed to reload curated friends: \(error)")
                        }
                    }
                }
        }
    }
}
