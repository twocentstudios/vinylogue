import Foundation
import Sharing

// MARK: - Type-Safe SharedReaderKey Extensions

// MARK: - App Storage Keys

extension SharedReaderKey where Self == AppStorageKey<String?> {
    /// Key for storing the current user's username
    static var currentUser: Self {
        appStorage("currentUser")
    }
}

extension SharedReaderKey where Self == AppStorageKey<Int>.Default {
    /// Key for storing the current play count filter with default value of 1
    static var currentPlayCountFilter: Self {
        Self[.appStorage("currentPlayCountFilter"), default: 1]
    }
}

extension SharedReaderKey where Self == AppStorageKey<Bool>.Default {
    /// Key for storing migration completion status with default value of false
    static var migrationCompleted: Self {
        Self[.appStorage("migration_completed_1_3_1"), default: false]
    }
}

// MARK: - File Storage Keys

extension SharedReaderKey where Self == FileStorageKey<[User]>.Default {
    /// Key for storing curated friends data with default empty array
    static var curatedFriends: Self {
        Self[.fileStorage(.curatedFriendsURL), default: []]
    }
}

// MARK: - In-Memory Keys

extension SharedReaderKey where Self == InMemoryKey<[AppModel.Path]>.Default {
    /// Key for storing navigation path in memory with default empty array
    static var navigationPath: Self {
        Self[.inMemory("navigationPath"), default: []]
    }
}

// MARK: - File URLs

extension URL {
    static let curatedFriendsURL = URL.documentsDirectory.appendingPathComponent("curatedFriends.json")
}
