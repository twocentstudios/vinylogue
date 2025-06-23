import Foundation

// MARK: - Legacy Data Models

/// Represents legacy user data stored in UserDefaults
class LegacyUser: NSObject, NSCoding {
    let username: String
    let realName: String?
    let imageThumbURL: String?
    let imageURL: String?
    let lastFMid: String?
    let url: String?

    /// The legacy UserDefaults key used to store the username
    static let userDefaultsKey = "lastFMUserName"

    init(username: String, realName: String? = nil, imageThumbURL: String? = nil, imageURL: String? = nil, lastFMid: String? = nil, url: String? = nil) {
        self.username = username
        self.realName = realName
        self.imageThumbURL = imageThumbURL
        self.imageURL = imageURL
        self.lastFMid = lastFMid
        self.url = url
        super.init()
    }

    // MARK: - NSCoding

    required init?(coder: NSCoder) {
        // Use the same keys as the legacy User class
        username = coder.decodeObject(forKey: "kUserUserName") as? String ?? ""
        realName = coder.decodeObject(forKey: "kUserRealName") as? String
        imageThumbURL = coder.decodeObject(forKey: "kUserImageThumbURL") as? String
        imageURL = coder.decodeObject(forKey: "kUserImageURL") as? String
        lastFMid = coder.decodeObject(forKey: "kUserLastFMid") as? String
        url = coder.decodeObject(forKey: "kUserURL") as? String
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(username, forKey: "kUserUserName")
        coder.encode(realName, forKey: "kUserRealName")
        coder.encode(imageThumbURL, forKey: "kUserImageThumbURL")
        coder.encode(imageURL, forKey: "kUserImageURL")
        coder.encode(lastFMid, forKey: "kUserLastFMid")
        coder.encode(url, forKey: "kUserURL")
    }
}

/// Represents legacy settings and preferences
struct LegacySettings: Codable, Sendable {
    let playCountFilter: Int?
    let lastOpenedDate: Date?

    /// Legacy UserDefaults keys for settings
    enum Keys {
        static let playCountFilter = "playCountFilter"
        static let lastOpenedDate = "lastOpenedDate"
        static let friendsList = "lastFMFriendsList"
    }
}

/// Represents legacy friends data that might have been cached
class LegacyFriend: NSObject, NSCoding {
    let username: String
    let realName: String?
    let playCount: Int?
    let imageURL: String?
    let imageThumbURL: String?
    let url: String?

    /// Legacy cache file name
    static let cacheFileName = "friends_cache.json"

    init(username: String, realName: String? = nil, playCount: Int? = nil, imageURL: String? = nil, imageThumbURL: String? = nil, url: String? = nil) {
        self.username = username
        self.realName = realName
        self.playCount = playCount
        self.imageURL = imageURL
        self.imageThumbURL = imageThumbURL
        self.url = url
        super.init()
    }

    // MARK: - NSCoding

    required init?(coder: NSCoder) {
        // Use the same keys as the legacy User class
        username = coder.decodeObject(forKey: "kUserUserName") as? String ?? ""
        realName = coder.decodeObject(forKey: "kUserRealName") as? String
        imageThumbURL = coder.decodeObject(forKey: "kUserImageThumbURL") as? String
        imageURL = coder.decodeObject(forKey: "kUserImageURL") as? String
        url = coder.decodeObject(forKey: "kUserURL") as? String
        playCount = nil // totalPlayCount was not persistent in the legacy User class
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(username, forKey: "kUserUserName")
        coder.encode(realName, forKey: "kUserRealName")
        coder.encode(imageThumbURL, forKey: "kUserImageThumbURL")
        coder.encode(imageURL, forKey: "kUserImageURL")
        coder.encode(url, forKey: "kUserURL")
        // Don't encode playCount as it wasn't persistent
    }
}

/// Container for all legacy data that needs migration
struct LegacyData {
    let user: LegacyUser?
    let settings: LegacySettings?
    let friends: [LegacyFriend]?
    let migrationDate: Date

    init(user: LegacyUser? = nil, settings: LegacySettings? = nil, friends: [LegacyFriend]? = nil) {
        self.user = user
        self.settings = settings
        self.friends = friends
        migrationDate = Date()
    }
}

// MARK: - Migration Extensions

extension LegacyUser {
    /// Converts legacy user to new User model
    func toUser() -> User {
        User(
            username: username,
            realName: realName,
            imageURL: imageURL ?? imageThumbURL, // Prefer full image, fallback to thumb
            url: url,
            playCount: nil // This field wasn't stored in User objects
        )
    }
}

extension LegacyFriend {
    /// Converts legacy friend to new User model
    func toUser() -> User {
        User(
            username: username,
            realName: realName,
            imageURL: imageURL ?? imageThumbURL, // Prefer full image, fallback to thumb
            url: url,
            playCount: playCount
        )
    }
}
