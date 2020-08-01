import Foundation

struct PersistenceClient {
    var loadUser: () -> User?
    var saveUser: (User?) -> ()
}

extension PersistenceClient {
    private static let userKey = "com.twocentstudios.userKey"

    private static let v1_friendsKey = "lastFMFriendsList"
    private static let v1_userNameKey = "lastFMUserName"

    static let live = Self(
        loadUser: {
            if let data = UserDefaults.standard.data(forKey: userKey),
                let user = try? JSONDecoder().decode(User.self, from: data) {
                return user
            }

            // Try to migrate data from V1
            NSKeyedUnarchiver.setClass(UserV1.self, forClassName: "User")
            if let userData = UserDefaults.standard.data(forKey: v1_userNameKey),
                let friendsData = UserDefaults.standard.data(forKey: v1_friendsKey),
                let user = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UserV1.self, from: userData),
                let friends = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(friendsData) as? [UserV1] {
                let migratedUser = User(
                    me: user.userName,
                    friends: friends.map(\.userName),
                    settings: .init(playCountFilter: .off)
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

@objc(UserV1) private final class UserV1: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true

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
