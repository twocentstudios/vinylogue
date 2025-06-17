import Foundation

// MARK: - User Weekly Chart List Response

struct UserWeeklyChartListResponse: Codable, Sendable {
    let weeklychartlist: WeeklyChartList
}

struct WeeklyChartList: Codable, Sendable {
    let chart: [ChartPeriod]?
    let attr: WeeklyChartListAttributes

    enum CodingKeys: String, CodingKey {
        case chart
        case attr = "@attr"
    }
}

struct ChartPeriod: Codable, Sendable {
    let from: String
    let to: String

    var fromDate: Date {
        Date(timeIntervalSince1970: TimeInterval(from) ?? 0)
    }

    var toDate: Date {
        Date(timeIntervalSince1970: TimeInterval(to) ?? 0)
    }
}

struct WeeklyChartListAttributes: Codable, Sendable {
    let user: String
}

// MARK: - User Weekly Album Chart Response

struct UserWeeklyAlbumChartResponse: Codable, Sendable {
    let weeklyalbumchart: WeeklyAlbumChart
}

struct WeeklyAlbumChart: Codable, Sendable {
    let album: [LastFMAlbumEntry]?
    let attr: WeeklyAlbumChartAttributes

    enum CodingKeys: String, CodingKey {
        case album
        case attr = "@attr"
    }
}

struct LastFMAlbumEntry: Codable, Sendable {
    let artist: LastFMArtist
    let mbid: String?
    let name: String
    let playcount: String
    let url: String?
    let attr: LastFMAlbumAttr

    enum CodingKeys: String, CodingKey {
        case artist, mbid, name, playcount, url
        case attr = "@attr"
    }

    struct LastFMAlbumAttr: Codable, Sendable {
        let rank: String
    }

    struct LastFMArtist: Codable, Sendable {
        let mbid: String?
        let name: String
        let url: String?

        enum CodingKeys: String, CodingKey {
            case mbid
            case name = "#text"
            case url
        }
    }

    var playCount: Int {
        Int(playcount) ?? 0
    }

    var rankNumber: Int? {
        Int(attr.rank)
    }
}

struct WeeklyAlbumChartAttributes: Codable, Sendable {
    let user: String
    let from: String
    let to: String
}

// MARK: - Album Info Response

struct AlbumInfoResponse: Codable, Sendable {
    let album: LastFMAlbumInfo
}

struct LastFMAlbumInfo: Codable, Sendable {
    let name: String
    let artist: String
    let mbid: String?
    let url: String?
    let image: [LastFMImage]?
    let playcount: String?
    let userplaycount: String?
    let wiki: LastFMWiki?

    var imageURL: String? {
        image?.last?.text
    }

    var totalPlayCount: Int? {
        if let playcount {
            return Int(playcount)
        }
        return nil
    }

    var userPlayCount: Int? {
        if let userplaycount {
            return Int(userplaycount)
        }
        return nil
    }

    var description: String? {
        wiki?.summary
    }
}

struct LastFMImage: Codable, Sendable {
    let text: String
    let size: String

    enum CodingKeys: String, CodingKey {
        case text = "#text"
        case size
    }
}

struct LastFMWiki: Codable, Sendable {
    let published: String?
    let summary: String?
    let content: String?
}

// MARK: - User Info Response

struct UserInfoResponse: Codable, Sendable {
    let user: LastFMUserInfo
}

struct LastFMUserInfo: Codable, Sendable {
    let name: String
    let realname: String?
    let url: String?
    let image: [LastFMImage]?
    let playcount: String?
    let registered: LastFMRegistered?

    var imageURL: String? {
        image?.last?.text
    }

    var totalPlayCount: Int? {
        if let playcount {
            return Int(playcount)
        }
        return nil
    }
}

struct LastFMRegistered: Codable, Sendable {
    let unixtime: String
    let text: Int

    enum CodingKeys: String, CodingKey {
        case unixtime
        case text = "#text"
    }
}

// MARK: - User Friends Response

struct UserFriendsResponse: Codable, Sendable {
    let friends: LastFMFriends
}

struct LastFMFriends: Codable, Sendable {
    let user: [LastFMFriend]
    let attr: UserFriendsAttributes

    enum CodingKeys: String, CodingKey {
        case user
        case attr = "@attr"
    }
}

struct LastFMFriend: Codable, Sendable {
    let name: String
    let realname: String?
    let url: String?
    let image: [LastFMImage]?
    let playcount: String?

    var imageURL: String? {
        image?.last?.text
    }

    var totalPlayCount: Int? {
        if let playcount {
            return Int(playcount)
        }
        return nil
    }
}

struct UserFriendsAttributes: Codable, Sendable {
    let user: String
    let totalPages: String
    let page: String
    let perPage: String
    let total: String
}
