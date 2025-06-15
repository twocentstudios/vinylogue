import Foundation

struct Album: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let artist: String
    let imageURL: String?
    let playCount: Int
    let rank: Int?
    let url: String?
    let mbid: String?

    // Detail view properties (loaded separately)
    var description: String?
    var totalPlayCount: Int?
    var userPlayCount: Int?
    var isDetailLoaded: Bool = false

    init(name: String, artist: String, imageURL: String? = nil, playCount: Int, rank: Int? = nil, url: String? = nil, mbid: String? = nil) {
        self.name = name
        self.artist = artist
        self.imageURL = imageURL
        self.playCount = playCount
        self.rank = rank
        self.url = url
        self.mbid = mbid
    }
}
