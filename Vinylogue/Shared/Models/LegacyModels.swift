import Foundation

// MARK: - Legacy Data Models

/// Represents legacy user data stored in UserDefaults
struct LegacyUser: Codable {
    let username: String
    
    /// The legacy UserDefaults key used to store the username
    static let userDefaultsKey = "kTCSUserDefaultsLastFMUserName"
}

/// Represents legacy settings and preferences
struct LegacySettings: Codable {
    let playCountFilter: Int?
    let lastOpenedDate: Date?
    
    /// Legacy UserDefaults keys for settings
    enum Keys {
        static let playCountFilter = "kTCSPlayCountFilter"
        static let lastOpenedDate = "kTCSLastOpenedDate"
    }
}

/// Represents legacy friends data that might have been cached
struct LegacyFriend: Codable {
    let username: String
    let realName: String?
    let playCount: Int?
    let imageURL: String?
    
    /// Legacy cache file name
    static let cacheFileName = "friends_cache.json"
}

/// Container for all legacy data that needs migration
struct LegacyData: Codable {
    let user: LegacyUser?
    let settings: LegacySettings?
    let friends: [LegacyFriend]?
    let migrationDate: Date
    
    init(user: LegacyUser? = nil, settings: LegacySettings? = nil, friends: [LegacyFriend]? = nil) {
        self.user = user
        self.settings = settings
        self.friends = friends
        self.migrationDate = Date()
    }
}

// MARK: - Migration Extensions

extension LegacyUser {
    /// Converts legacy user to new User model
    func toUser() -> User {
        return User(
            username: username,
            realName: nil,
            imageURL: nil,
            url: nil,
            playCount: nil
        )
    }
}

extension LegacyFriend {
    /// Converts legacy friend to new User model
    func toUser() -> User {
        return User(
            username: username,
            realName: realName,
            imageURL: imageURL,
            url: nil,
            playCount: playCount
        )
    }
}