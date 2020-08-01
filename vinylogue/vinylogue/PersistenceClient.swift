import Foundation

struct PersistenceClient {
    var loadUser: () -> User?
    var saveUser: (User?) -> ()
}

extension PersistenceClient {
    private static let userKey = "com.twocentstudios.userKey"

    private static let v1_friendsKey = "lastFMFriendsList"
    private static let v1_userNameKey = "lastFMUserName"
    private static let v1_playCountFilterKey = "playCountFilter"

    static let live = Self(
        loadUser: {
            if let data = UserDefaults.standard.data(forKey: userKey),
                let user = try? JSONDecoder().decode(User.self, from: data) {
                return user
            }

            // Try to migrate data from V1
            if let userData = UserDefaults.standard.data(forKey: v1_userNameKey),
               let friendsData = UserDefaults.standard.data(forKey: v1_friendsKey),
               let playCountFilterData = UserDefaults.standard.data(forKey: v1_playCountFilterKey),
               let user = NSKeyedUnarchiver.unarchiveObject(with: userData) as? UserV1,
               let friends = NSKeyedUnarchiver.unarchiveObject(with: friendsData) as? [UserV1] {
               let playCountFilterInt = UserDefaults.standard.integer(forKey: v1_playCountFilterKey)
                let playCountFilterString = String(playCountFilterInt)
                let playCountFilter = Settings.PlayCountFilter(rawValue: playCountFilterString) ?? .off

                let migratedUser = User(
                    me: user.userName,
                    friends: friends.map(\.userName),
                    settings: .init(playCountFilter: playCountFilter)
                )
                return migratedUser
            }

            return nil
        },
        saveUser: { user in
            let data = try? JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: userKey)
        }
    )
}

@objc(UserV1) private final class UserV1: NSObject, NSCoding {
    let userName: String

    init(userName: String) {
        self.userName = userName
    }

    init?(coder: NSCoder) {
        guard let userName = coder.decodeObject(forKey: "kUserUserName") as? String else { return nil }
        self.userName = userName
    }

    func encode(with coder: NSCoder) {
        fatalError("Encoding is not supported")
    }
}
