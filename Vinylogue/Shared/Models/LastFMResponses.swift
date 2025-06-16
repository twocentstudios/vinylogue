import Foundation

// MARK: - User Weekly Chart List Response

struct UserWeeklyChartListResponse: Codable {
    let weeklychartlist: WeeklyChartList
}

struct WeeklyChartList: Codable {
    let chart: [ChartPeriod]
    let attr: WeeklyChartListAttributes

    enum CodingKeys: String, CodingKey {
        case chart
        case attr = "@attr"
    }
}

struct ChartPeriod: Codable {
    let from: String
    let to: String

    var fromDate: Date {
        Date(timeIntervalSince1970: TimeInterval(from) ?? 0)
    }

    var toDate: Date {
        Date(timeIntervalSince1970: TimeInterval(to) ?? 0)
    }
}

struct WeeklyChartListAttributes: Codable {
    let user: String
}

// MARK: - User Weekly Album Chart Response

struct UserWeeklyAlbumChartResponse: Codable {
    let weeklyalbumchart: WeeklyAlbumChart
}

struct WeeklyAlbumChart: Codable {
    let album: [LastFMAlbumEntry]
    let attr: WeeklyAlbumChartAttributes

    enum CodingKeys: String, CodingKey {
        case album
        case attr = "@attr"
    }
}

struct LastFMAlbumEntry: Codable {
    let artist: LastFMArtist
    let mbid: String?
    let name: String
    let playcount: String
    let rank: String
    let url: String?

    struct LastFMArtist: Codable {
        let mbid: String?
        let name: String
        let url: String?

        enum CodingKeys: String, CodingKey {
            case mbid = "#text"
            case name
            case url
        }
    }

    var playCount: Int {
        Int(playcount) ?? 0
    }

    var rankNumber: Int? {
        Int(rank)
    }
}

struct WeeklyAlbumChartAttributes: Codable {
    let user: String
    let from: String
    let to: String
}

// MARK: - Album Info Response

struct AlbumInfoResponse: Codable {
    let album: LastFMAlbumInfo
}

struct LastFMAlbumInfo: Codable {
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

struct LastFMImage: Codable {
    let text: String
    let size: String

    enum CodingKeys: String, CodingKey {
        case text = "#text"
        case size
    }
}

struct LastFMWiki: Codable {
    let published: String?
    let summary: String?
    let content: String?
}

// MARK: - User Info Response

struct UserInfoResponse: Codable {
    let user: LastFMUserInfo
}

struct LastFMUserInfo: Codable {
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

struct LastFMRegistered: Codable {
    let unixtime: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case unixtime
        case text = "#text"
    }
}

// MARK: - User Friends Response

struct UserFriendsResponse: Codable {
    let friends: LastFMFriends
}

struct LastFMFriends: Codable {
    let user: [LastFMFriend]
    let attr: UserFriendsAttributes

    enum CodingKeys: String, CodingKey {
        case user
        case attr = "@attr"
    }
}

struct LastFMFriend: Codable {
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

struct UserFriendsAttributes: Codable {
    let user: String
    let totalPages: String
    let page: String
    let perPage: String
    let total: String
}
