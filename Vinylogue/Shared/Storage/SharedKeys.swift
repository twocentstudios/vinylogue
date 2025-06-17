import Foundation
import Sharing

// MARK: - File URLs

extension URL {
    /// File URL for storing curated friends data
    static let curatedFriendsURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("curatedFriends.json")
}
