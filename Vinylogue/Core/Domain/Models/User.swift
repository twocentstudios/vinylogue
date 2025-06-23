import Foundation

struct User: Codable, Identifiable, Hashable, Sendable {
    var id: String { username.lowercased() }
    let username: String
    let realName: String?
    let imageURL: String?
    let url: String?
    let playCount: Int?

    // Legacy migration keys
    static let legacyUserDefaultsKey = "kTCSUserDefaultsLastFMUserName"

    init(username: String, realName: String? = nil, imageURL: String? = nil, url: String? = nil, playCount: Int? = nil) {
        self.username = username
        self.realName = realName
        self.imageURL = imageURL
        self.url = url
        self.playCount = playCount
    }
}
