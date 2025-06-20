import Dependencies
import Nuke
import Sharing
import SwiftUI

@main
struct VinylogueApp: App {
    var body: some Scene {
        WindowGroup {
            if isTesting, !isScreenshotTesting {
                EmptyView()
            } else {
                RootView()
                    .task {
                        if isScreenshotTesting {
                            await setupScreenshotTestData()
                        } else {
                            #if DEBUG
                                @Dependency(\.cacheManager) var cacheManager
                                try! await cacheManager.clearCache()
                            #endif
                        }
                    }
            }
        }
    }

    @MainActor
    private func setupScreenshotTestData() async {
        // Set up current user
        if let currentUser = TestingUtilities.getTestString(for: "CURRENT_USER") {
            @Shared(.currentUser) var currentUsername: String?
            $currentUsername.withLock { $0 = currentUser }
        }

        // Set up friends data
        if let friendsJSON = TestingUtilities.getTestString(for: "FRIENDS_DATA"),
           let friendsData = friendsJSON.data(using: .utf8)
        {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: friendsData, options: [])
                if let friendsArray = jsonObject as? [[String: Any]] {
                    let friends = friendsArray.compactMap { dict -> User? in
                        guard let username = dict["username"] as? String else { return nil }
                        let realName = dict["realName"] as? String
                        let playCount = dict["playCount"] as? Int
                        return User(username: username, realName: realName, imageURL: nil, url: nil, playCount: playCount)
                    }

                    @Shared(.curatedFriends) var curatedFriends: [User]
                    $curatedFriends.withLock { $0 = friends }
                }
            } catch {
                print("Failed to decode friends data: \(error)")
            }
        }
    }
}
