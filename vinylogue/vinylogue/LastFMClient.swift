import Combine
import ComposableArchitecture
import Foundation

struct LastFMClient {
    let verifyUsername: (String) -> Effect<Username, Error>
    let friendsForUsername: (Username) -> Effect<[Username], Error>
    let weeklyChartList: (Username) -> Effect<LastFM.WeeklyChartList, Error>
    let weeklyAlbumChart: (Username, LastFM.WeeklyChartRange) -> Effect<LastFM.WeeklyAlbumCharts, Error>
    let album: (Username, LastFM.ArtistStub, LastFM.AlbumStub) -> Effect<LastFM.Album, Error>
}

extension LastFMClient {
    // TODO: LocalizedError
    enum Error: Equatable, Swift.Error {
        case api(LastFM.Error)
        case system(URLError)
        case http(Int)
        case badResponse
        case unknown
        case decoding(String)
    }
}

extension LastFMClient {
    static let live = Self(
        verifyUsername: { (username: String) -> Effect<Username, Error> in
            let request = LastFM.GetUserRequest(username: username)
            return fetch(request).map(\.user.username)
        },
        friendsForUsername: { (username: Username) -> Effect<[Username], Error> in
            let request = LastFM.GetFriendsRequest(username: username)
            return fetch(request).map { $0.friends.map(\.username) }
        },
        weeklyChartList: { (username: Username) -> Effect<LastFM.WeeklyChartList, Error> in
            let request = LastFM.GetWeeklyChartListRequest(username: username)
            return fetch(request).map(\.weeklyChartList)
        },
        weeklyAlbumChart: { (username: Username, range: LastFM.WeeklyChartRange) -> Effect<LastFM.WeeklyAlbumCharts, Error> in
            let request = LastFM.GetWeeklyAlbumChartRequest(username: username, range: range)
            return fetch(request).map(\.weeklyAlbumCharts)
        },
        album: { (username: Username, artist: LastFM.ArtistStub, album: LastFM.AlbumStub) -> Effect<LastFM.Album, Error> in
            let request = LastFM.GetAlbumRequest(username: username, artist: artist, album: album)
            return fetch(request).map(\.album)
        }
    )

    private static let baseRequest = LastFM.Request(apiKey: "")
    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    private static func fetch<Request: LastFMRequest>(_ request: Request) -> Effect<Request.Response, Error> {
        let urlRequest = baseRequest.urlRequest(with: request.queryItems)
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, urlResponse -> Request.Response in
                guard let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode else {
                    throw Error.badResponse
                }
                guard statusCode >= 200,
                    statusCode < 400
                else {
                    throw Error.http(statusCode)
                }
                if let apiError = try? jsonDecoder.decode(LastFM.Error.self, from: data) {
                    throw Error.api(apiError)
                }
                do {
                    return try jsonDecoder.decode(Request.Response.self, from: data)
                } catch {
                    throw Error.decoding(error.localizedDescription)
                }
            }
            .mapError { error -> Error in
                if let error = error as? Error {
                    return error
                } else if let error = error as? URLError {
                    return Error.system(error)
                }
                return Error.unknown
            }
            .eraseToEffect()
    }
}

// Namespace
enum LastFM {}

protocol LastFMRequest {
    associatedtype Response: Decodable
    var queryItems: [URLQueryItem] { get }
}

extension LastFM.GetUserRequest: LastFMRequest {}
extension LastFM.GetFriendsRequest: LastFMRequest {}
extension LastFM.GetWeeklyChartListRequest: LastFMRequest {}
extension LastFM.GetWeeklyAlbumChartRequest: LastFMRequest {}
extension LastFM.GetAlbumRequest: LastFMRequest {}

extension LastFM {
    struct Request: Equatable {
        let baseURL: URL = URL(string: "https://ws.audioscrobbler.com/2.0/")!
        let apiKey: String
        let format = "json"
        let method = "GET"
        let accept = "application/json"

        func urlRequest(with queryItems: [URLQueryItem]) -> URLRequest {
            let defaultQueryItems = [
                URLQueryItem(name: "api_key", value: apiKey),
                URLQueryItem(name: "format", value: format),
            ]

            var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = defaultQueryItems + queryItems

            var request = URLRequest(url: urlComponents.url!)
            request.setValue(accept, forHTTPHeaderField: "Accept")
            request.setValue(nil, forHTTPHeaderField: "Accept-Encoding")
            request.httpMethod = method
            return request
        }
    }

    struct GetUserRequest {
        typealias Response = GetUserResponse
        let method = "user.getinfo"
        let username: Username

        var queryItems: [URLQueryItem] {
            [
                URLQueryItem(name: "method", value: method),
                URLQueryItem(name: "user", value: username),
            ]
        }
    }

    struct GetFriendsRequest {
        typealias Response = GetFriendsResponse
        let method = "user.getfriends"
        let username: Username
        let limit = "500"

        var queryItems: [URLQueryItem] {
            [
                URLQueryItem(name: "method", value: method),
                URLQueryItem(name: "user", value: username),
                URLQueryItem(name: "limit", value: limit),
            ]
        }
    }

    struct GetWeeklyChartListRequest {
        typealias Response = GetWeeklyChartListResponse
        let method = "user.getweeklychartlist"
        let username: Username

        var queryItems: [URLQueryItem] {
            [
                URLQueryItem(name: "method", value: method),
                URLQueryItem(name: "user", value: username),
            ]
        }
    }

    struct GetWeeklyAlbumChartRequest {
        typealias Response = GetWeeklyAlbumChartResponse
        let method = "user.getweeklyalbumchart"
        let username: Username
        let range: WeeklyChartRange

        var queryItems: [URLQueryItem] {
            [
                URLQueryItem(name: "method", value: method),
                URLQueryItem(name: "user", value: username),
                URLQueryItem(name: "from", value: String(range.from.timeIntervalSince1970)),
                URLQueryItem(name: "to", value: String(range.to.timeIntervalSince1970)),
            ]
        }
    }

    struct GetAlbumRequest {
        typealias Response = GetAlbumResponse
        let method = "album.getinfo"
        let username: Username
        let artist: ArtistStub
        let album: AlbumStub

        var queryItems: [URLQueryItem] {
            var items = [
                URLQueryItem(name: "method", value: method),
                URLQueryItem(name: "username", value: username),
            ]

            if let mbid = album.mbid {
                items.append(URLQueryItem(name: "mbid", value: mbid))
            } else {
                items.append(contentsOf: [
                    URLQueryItem(name: "artist", value: artist.name),
                    URLQueryItem(name: "artist", value: album.name),
                ])
            }

            return items
        }
    }
}

extension LastFM {
    struct GetUserResponse: Equatable, Decodable {
        let user: User
    }

    struct GetFriendsResponse: Equatable, Decodable {
        let friends: [User]

        enum CodingKeys: String, CodingKey {
            case friends
        }

        enum FriendsKeys: String, CodingKey {
            case user // array
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let friendsContainer = try values.nestedContainer(keyedBy: FriendsKeys.self, forKey: .friends)
            friends = try friendsContainer.decode([User].self, forKey: .user)
        }
    }

    struct GetWeeklyChartListResponse: Equatable, Decodable {
        let weeklyChartList: WeeklyChartList
    }

    struct GetWeeklyAlbumChartResponse: Equatable, Decodable {
        let weeklyAlbumCharts: WeeklyAlbumCharts

        enum CodingKeys: String, CodingKey {
            case weeklyAlbumCharts = "weeklyalbumchart"
        }
    }

    struct GetAlbumResponse: Equatable, Decodable {
        let album: Album
    }
}

extension LastFM {
    struct User: Equatable, Decodable {
        let username: String

        enum CodingKeys: String, CodingKey {
            case username = "name"
        }
    }

    struct Friends: Equatable, Decodable {
        let friends: [User]

        enum CodingKeys: String, CodingKey {
            case friends = "user"
        }
    }

    struct WeeklyChartList: Equatable, Decodable {
        let ranges: [WeeklyChartRange]

        enum CodingKeys: String, CodingKey {
            case ranges = "chart"
        }
    }

    struct WeeklyChartRange: Equatable, Hashable, Decodable {
        let from: Date // unix timestamp
        let to: Date
    }

    struct WeeklyAlbumCharts: Equatable, Decodable {
        let charts: [WeeklyAlbumChartStub]

        enum CodingKeys: String, CodingKey {
            case charts = "album"
        }
    }

    struct WeeklyAlbumChartStub: Equatable, Hashable, Decodable {
        let album: AlbumStub
        let artist: ArtistStub
        let playCount: Int

        enum CodingKeys: String, CodingKey {
            case name
            case mbid
            case playCount = "playcount"
            case artist
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let name = try values.decode(String.self, forKey: .name)
            let mbid = try values.decodeIfPresent(String.self, forKey: .mbid)
            album = AlbumStub(mbid: mbid, name: name)
            artist = try values.decode(ArtistStub.self, forKey: .artist)
            playCount = try values.decode(Int.self, forKey: .playCount)
        }
    }

    struct ArtistStub: Equatable, Hashable, Decodable {
        let mbid: String?
        let name: String

        enum CodingKeys: String, CodingKey {
            case mbid
            case name = "#text"
        }
    }

    struct AlbumStub: Equatable, Hashable {
        let mbid: String?
        let name: String
    }

    struct Album: Equatable, Hashable, Decodable {
        let mbid: String?
        let name: String
        // let releaseDate: Date
        let artist: String
        let totalPlayCount: Int?
        let about: String?
        let tracks: [Track]?
        let imageSet: ImageSet?

        enum CodingKeys: String, CodingKey {
            case mbid
            case name
            case artist
            case image
            case totalPlayCount = "userplaycount"
            case wiki
            case tracks
        }

        enum WikiKeys: String, CodingKey {
            case content
        }

        enum TracksKeys: String, CodingKey {
            case track // array
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            mbid = try values.decodeIfPresent(String.self, forKey: .mbid)
            name = try values.decode(String.self, forKey: .name)
            artist = try values.decode(String.self, forKey: .artist)
            totalPlayCount = try values.decodeIfPresent(Int.self, forKey: .totalPlayCount)

            // TODO: clean up content HTML
            let wikiValues = try values.nestedContainer(keyedBy: WikiKeys.self, forKey: .wiki)
            about = try wikiValues.decodeIfPresent(String.self, forKey: .content)

            let tracksValues = try values.nestedContainer(keyedBy: TracksKeys.self, forKey: .tracks)
            tracks = try tracksValues.decodeIfPresent([Track].self, forKey: .track)

            let imageValues = try values.decodeIfPresent([Image].self, forKey: .image)
            imageSet = imageValues.map { ImageSet(images: $0) }
        }
    }

    struct Track: Equatable, Hashable, Decodable {
        let name: String
        let seconds: Int?

        enum CodingKeys: String, CodingKey {
            case name
            case seconds = "duration"
        }
    }

    struct ImageSet: Equatable, Hashable, Decodable {
        let images: [Image]
    }

    struct Image: Equatable, Hashable, Decodable {
        let url: URL
        let size: String?

        enum CodingKeys: String, CodingKey {
            case url = "#text"
            case size
        }
    }

    struct Error: Swift.Error, Equatable, Decodable {
        let message: String
        let code: Int

        var title: String {
            switch code {
            case 2: return "Invalid service"
            case 3: return "Invalid method"
            case 4: return "Authentication failed"
            case 5: return "Invalid format"
            case 6: return "Invalid parameters"
            case 7: return "Invalid resource specified"
            case 8: return "Operation failed"
            case 9: return "Invalid session key"
            case 10: return "Invalid API key"
            case 11: return "Service offline"
            case 12: return "Subscribers only"
            case 13: return "Invalid method signature supplied"
            case 14: return "Unauthorized token"
            case 15: return "Streaming unavailable"
            case 16: return "Service temporarily unavailable"
            case 17: return "Login required"
            case 18: return "Trial expired"
            case 20: return "Not enough content"
            case 21: return "Not enough members"
            case 22: return "Not enough fans"
            case 23: return "Not enough neighbors"
            case 24: return "No peak radio"
            case 25: return "Radio not found"
            case 26: return "API key suspended"
            case 27: return "Deprecated"
            case 29: return "Rate limit exceeded"
            default: return "Unknown error"
            }
        }

        var subtitle: String {
            switch code {
            case 2: return "This service does not exist."
            case 3: return "No method with that name in this package."
            case 4: return "You do not have permissions to access the service."
            case 5: return "This service doesn't exist in that format."
            case 6: return "Your request is missing a required parameter."
            case 7: return ""
            case 8: return "The backend service failed. Please try again."
            case 9: return "Please re-authenticate."
            case 10: return "You must be granted a valid key by last.fm."
            case 11: return "This service is temporarily offline. Please try again later."
            case 12: return "This station is only available to paid last.fm subscribers"
            case 13: return ""
            case 14: return "This token has not been authorized."
            case 15: return "This item is not available for streaming."
            case 16: return "The service is temporarily unavailable. Please try again."
            case 17: return "User must be logged in."
            case 18: return "This user has no free radio plays left."
            case 20: return "There is not enough content to play this station."
            case 21: return "This group does not have enough members for radio."
            case 22: return "This artist does not have enough fans for radio."
            case 23: return "There are not enough neighbors for radio."
            case 24: return "This user is not allowed to listen to radio during peak usage."
            case 25: return "Radio station not found."
            case 26: return "This application is not allowed to maek requests to the web services."
            case 27: return "This type of request is no longer supported."
            case 29: return "Your IP has made too many requests in a short period. Please try again later."
            default: return "Unknown error"
            }
        }
    }
}

extension LastFM.ImageSet {
    /// LastFM's image size labels aren't that useful, so we just assume the last entry is the largest.
    var url: URL? {
        images.last?.url
    }

    /// The largest entry is often not even big enough for a thumbnail size, so just use the largest.
    var thumbnailURL: URL? {
        url
    }
}

#if DEBUG
extension LastFMClient {
    static let mock = Self(
        verifyUsername: { (username: String) -> Effect<Username, Error> in
            let response: Effect<LastFM.GetUserResponse, Error> = mockJsonFetch(LastFM.user_getInfo_json)
            return response.map(\.user.username)
        },
        friendsForUsername: { (username: Username) -> Effect<[Username], Error> in
            let response: Effect<LastFM.GetFriendsResponse, Error> = mockJsonFetch(LastFM.user_getFriends_json)
            return response.map { $0.friends.map(\.username) }
        },
        weeklyChartList: { (username: Username) -> Effect<LastFM.WeeklyChartList, Error> in
            let response: Effect<LastFM.GetWeeklyChartListResponse, Error> = mockJsonFetch(LastFM.user_getWeeklyChartList_json)
            return response.map(\.weeklyChartList)
        },
        weeklyAlbumChart: { (username: Username, range: LastFM.WeeklyChartRange) -> Effect<LastFM.WeeklyAlbumCharts, Error> in
            let response: Effect<LastFM.GetWeeklyAlbumChartResponse, Error> = mockJsonFetch(LastFM.user_getWeeklyChart_json)
            return response.map(\.weeklyAlbumCharts)
        },
        album: { (username: Username, artist: LastFM.ArtistStub, album: LastFM.AlbumStub) -> Effect<LastFM.Album, Error> in
            let response: Effect<LastFM.GetAlbumResponse, Error> = mockJsonFetch(LastFM.album_getInfo_json)
            return response.map(\.album)
        }
    )

    private static func mockJsonFetch<Response: Decodable>(_ json: String) -> Effect<Response, Error> {
        return Just(json.data(using: .utf8)!)
            .decode(type: Response.self, decoder: jsonDecoder)
            .mapError { error -> Error in
                if let error = error as? Error {
                    return error
                } else if let error = error as? URLError {
                    return Error.system(error)
                } else if let error = error as? DecodingError {
                    print(error)
                    return Error.decoding(error.localizedDescription)
                }
                return Error.unknown
            }
//            .delay(for: .seconds(1.5), scheduler: DispatchQueue.main.eraseToAnyScheduler()) // TODO: Testing only
            .eraseToEffect()
    }
}

extension LastFM {
    static let user_getInfo_json = #"""
    {"user":{"playlists":"0","playcount":"88865","gender":"n","name":"ybsc","subscriber":"0","url":"https:\/\/www.last.fm\/user\/ybsc","country":"United States","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/44573caedd384c4fccdb73b99aaa5b6e.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/44573caedd384c4fccdb73b99aaa5b6e.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/44573caedd384c4fccdb73b99aaa5b6e.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/44573caedd384c4fccdb73b99aaa5b6e.png"}],"registered":{"unixtime":"1200017507","#text":1200017507},"type":"user","age":"0","bootstrap":"0","realname":"Christopher Trott"}}
    """#

    static let user_getFriends_json = #"""
    {"friends":{"user":[{"playlists":"0","playcount":"0","subscriber":"0","name":"heyimtaka0121","country":"Japan","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/c4fdc4ebff6459912f0f9e8dd364057f.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/c4fdc4ebff6459912f0f9e8dd364057f.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/c4fdc4ebff6459912f0f9e8dd364057f.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/c4fdc4ebff6459912f0f9e8dd364057f.png"}],"registered":{"unixtime":"1480776329","#text":"2016-12-03 14:45"},"url":"https:\/\/www.last.fm\/user\/heyimtaka0121","realname":"","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"roguewolves","country":"Australia","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/34422da8c10a41bdc105f39d628078b5.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/34422da8c10a41bdc105f39d628078b5.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/34422da8c10a41bdc105f39d628078b5.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/34422da8c10a41bdc105f39d628078b5.png"}],"registered":{"unixtime":"1243942070","#text":"2009-06-02 11:27"},"url":"https:\/\/www.last.fm\/user\/roguewolves","realname":"Neal","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"The-Riot-Before","country":"United States","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/e03876a404e04211c2c2445c51cf5aa5.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/e03876a404e04211c2c2445c51cf5aa5.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/e03876a404e04211c2c2445c51cf5aa5.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/e03876a404e04211c2c2445c51cf5aa5.png"}],"registered":{"unixtime":"1275893724","#text":"2010-06-07 06:55"},"url":"https:\/\/www.last.fm\/user\/The-Riot-Before","realname":"Logan Slawson","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"MiniWh3ats","country":"United States","image":[{"size":"small","#text":""},{"size":"medium","#text":""},{"size":"large","#text":""},{"size":"extralarge","#text":""}],"registered":{"unixtime":"1238988448","#text":"2009-04-06 03:27"},"url":"https:\/\/www.last.fm\/user\/MiniWh3ats","realname":"","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"Phantos","country":"United States","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/547e2b0d078241fec1c9a049d5e0c4d1.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/547e2b0d078241fec1c9a049d5e0c4d1.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/547e2b0d078241fec1c9a049d5e0c4d1.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/547e2b0d078241fec1c9a049d5e0c4d1.png"}],"registered":{"unixtime":"1177176718","#text":"2007-04-21 17:31"},"url":"https:\/\/www.last.fm\/user\/Phantos","realname":"Jeff","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"lackenir","country":"United States","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/ca618926af404350c3aa369de2e9822f.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/ca618926af404350c3aa369de2e9822f.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/ca618926af404350c3aa369de2e9822f.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/ca618926af404350c3aa369de2e9822f.png"}],"registered":{"unixtime":"1152280383","#text":"2006-07-07 13:53"},"url":"https:\/\/www.last.fm\/user\/lackenir","realname":"Nick","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"MischiefMike","country":"United States","image":[{"size":"small","#text":""},{"size":"medium","#text":""},{"size":"large","#text":""},{"size":"extralarge","#text":""}],"registered":{"unixtime":"1269455937","#text":"2010-03-24 18:38"},"url":"https:\/\/www.last.fm\/user\/MischiefMike","realname":"Mike Gongol","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"julie1ann","country":"None","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/f99defb25e554ca9ccc9fbecb7e3c320.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/f99defb25e554ca9ccc9fbecb7e3c320.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/f99defb25e554ca9ccc9fbecb7e3c320.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/f99defb25e554ca9ccc9fbecb7e3c320.png"}],"registered":{"unixtime":"1232266412","#text":"2009-01-18 08:13"},"url":"https:\/\/www.last.fm\/user\/julie1ann","realname":"","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"Lowebot","country":"None","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/9416968010d3464fc6fb52c0c1657a6f.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/9416968010d3464fc6fb52c0c1657a6f.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/9416968010d3464fc6fb52c0c1657a6f.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/9416968010d3464fc6fb52c0c1657a6f.png"}],"registered":{"unixtime":"1074056742","#text":"2004-01-14 05:05"},"url":"https:\/\/www.last.fm\/user\/Lowebot","realname":"","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"itschinatown","country":"United States","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/6808e36c900c4b8ccbe026aabc2c1e22.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/6808e36c900c4b8ccbe026aabc2c1e22.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/6808e36c900c4b8ccbe026aabc2c1e22.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/6808e36c900c4b8ccbe026aabc2c1e22.png"}],"registered":{"unixtime":"1193339473","#text":"2007-10-25 19:11"},"url":"https:\/\/www.last.fm\/user\/itschinatown","realname":"T.J.","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"slippydrums","country":"United States","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/1073141fe098424fc21740900667df7d.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/1073141fe098424fc21740900667df7d.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/1073141fe098424fc21740900667df7d.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/1073141fe098424fc21740900667df7d.png"}],"registered":{"unixtime":"1210144073","#text":"2008-05-07 07:07"},"url":"https:\/\/www.last.fm\/user\/slippydrums","realname":"Hutch","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"greendayaddict","country":"United Kingdom","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/60ef2369b63f47edc7a9ca4b46c07a22.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/60ef2369b63f47edc7a9ca4b46c07a22.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/60ef2369b63f47edc7a9ca4b46c07a22.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/60ef2369b63f47edc7a9ca4b46c07a22.png"}],"registered":{"unixtime":"1170587034","#text":"2007-02-04 11:03"},"url":"https:\/\/www.last.fm\/user\/greendayaddict","realname":" Mary Yasmine","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"seejayperry","country":"United States","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/96c500b476f2c06eace3e96362ab1d58.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/96c500b476f2c06eace3e96362ab1d58.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/96c500b476f2c06eace3e96362ab1d58.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/96c500b476f2c06eace3e96362ab1d58.png"}],"registered":{"unixtime":"1205951362","#text":"2008-03-19 18:29"},"url":"https:\/\/www.last.fm\/user\/seejayperry","realname":"CJ Oltman","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"esheikh","country":"United States","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/a7dae3c50bbb42a2c278c50b6bf5156e.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/a7dae3c50bbb42a2c278c50b6bf5156e.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/a7dae3c50bbb42a2c278c50b6bf5156e.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/a7dae3c50bbb42a2c278c50b6bf5156e.png"}],"registered":{"unixtime":"1130276514","#text":"2005-10-25 21:41"},"url":"https:\/\/www.last.fm\/user\/esheikh","realname":"","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"HeIsMeaty","country":"None","image":[{"size":"small","#text":""},{"size":"medium","#text":""},{"size":"large","#text":""},{"size":"extralarge","#text":""}],"registered":{"unixtime":"1180598542","#text":"2007-05-31 08:02"},"url":"https:\/\/www.last.fm\/user\/HeIsMeaty","realname":"","bootstrap":"0","type":"user"},{"playlists":"0","playcount":"0","subscriber":"0","name":"BobbyStompy","country":"United States","image":[{"size":"small","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/34s\/6aa192f347b9421ac21861b4c9d86f37.png"},{"size":"medium","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/64s\/6aa192f347b9421ac21861b4c9d86f37.png"},{"size":"large","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/174s\/6aa192f347b9421ac21861b4c9d86f37.png"},{"size":"extralarge","#text":"https:\/\/lastfm.freetls.fastly.net\/i\/u\/300x300\/6aa192f347b9421ac21861b4c9d86f37.png"}],"registered":{"unixtime":"1157269199","#text":"2006-09-03 07:39"},"url":"https:\/\/www.last.fm\/user\/BobbyStompy","realname":"Bobby Stompy","bootstrap":"0","type":"user"}],"@attr":{"page":"1","perPage":"500","user":"ybsc","total":"16","totalPages":"1"}}}
    """#

    static let user_getWeeklyChartList_json = #"""
    {"weeklychartlist":{"chart":[{"#text":"","from":"1108296000","to":"1108900800"},{"#text":"","from":"1108900800","to":"1109505600"},{"#text":"","from":"1109505600","to":"1110110400"},{"#text":"","from":"1110110400","to":"1110715200"},{"#text":"","from":"1110715200","to":"1111320000"},{"#text":"","from":"1111320000","to":"1111924800"},{"#text":"","from":"1111924800","to":"1112529600"},{"#text":"","from":"1112529600","to":"1113134400"},{"#text":"","from":"1113134400","to":"1113739200"},{"#text":"","from":"1113739200","to":"1114344000"},{"#text":"","from":"1114344000","to":"1114948800"},{"#text":"","from":"1114948800","to":"1115553600"},{"#text":"","from":"1115553600","to":"1116158400"},{"#text":"","from":"1116158400","to":"1116763200"},{"#text":"","from":"1116763200","to":"1117368000"},{"#text":"","from":"1117368000","to":"1117972800"},{"#text":"","from":"1117972800","to":"1118577600"},{"#text":"","from":"1118577600","to":"1119182400"},{"#text":"","from":"1119182400","to":"1119787200"},{"#text":"","from":"1119787200","to":"1120392000"},{"#text":"","from":"1120392000","to":"1120996800"},{"#text":"","from":"1120996800","to":"1121601600"},{"#text":"","from":"1121601600","to":"1122206400"},{"#text":"","from":"1122206400","to":"1122811200"},{"#text":"","from":"1122811200","to":"1123416000"},{"#text":"","from":"1123416000","to":"1124020800"},{"#text":"","from":"1124020800","to":"1124625600"},{"#text":"","from":"1124625600","to":"1125230400"},{"#text":"","from":"1125230400","to":"1125835200"},{"#text":"","from":"1125835200","to":"1126440000"},{"#text":"","from":"1126440000","to":"1127044800"},{"#text":"","from":"1127044800","to":"1127649600"},{"#text":"","from":"1127649600","to":"1128254400"},{"#text":"","from":"1128254400","to":"1128859200"},{"#text":"","from":"1128859200","to":"1129464000"},{"#text":"","from":"1129464000","to":"1130068800"},{"#text":"","from":"1130068800","to":"1130673600"},{"#text":"","from":"1130673600","to":"1131278400"},{"#text":"","from":"1131278400","to":"1131883200"},{"#text":"","from":"1131883200","to":"1132488000"},{"#text":"","from":"1132488000","to":"1133092800"},{"#text":"","from":"1133092800","to":"1133697600"},{"#text":"","from":"1133697600","to":"1134302400"},{"#text":"","from":"1134302400","to":"1134907200"},{"#text":"","from":"1134907200","to":"1135512000"},{"#text":"","from":"1135512000","to":"1136116800"},{"#text":"","from":"1136116800","to":"1136721600"},{"#text":"","from":"1136721600","to":"1137326400"},{"#text":"","from":"1137326400","to":"1137931200"},{"#text":"","from":"1137931200","to":"1138536000"},{"#text":"","from":"1138536000","to":"1139140800"},{"#text":"","from":"1139140800","to":"1139745600"},{"#text":"","from":"1139745600","to":"1140350400"},{"#text":"","from":"1140350400","to":"1140955200"},{"#text":"","from":"1140955200","to":"1141560000"},{"#text":"","from":"1141560000","to":"1142164800"},{"#text":"","from":"1142164800","to":"1142769600"},{"#text":"","from":"1142769600","to":"1143374400"},{"#text":"","from":"1143374400","to":"1143979200"},{"#text":"","from":"1143979200","to":"1144584000"},{"#text":"","from":"1144584000","to":"1145188800"},{"#text":"","from":"1145188800","to":"1145793600"},{"#text":"","from":"1145793600","to":"1146398400"},{"#text":"","from":"1146398400","to":"1147003200"},{"#text":"","from":"1147003200","to":"1147608000"},{"#text":"","from":"1147608000","to":"1148212800"},{"#text":"","from":"1148212800","to":"1148817600"},{"#text":"","from":"1148817600","to":"1149422400"},{"#text":"","from":"1149422400","to":"1150027200"},{"#text":"","from":"1150027200","to":"1150632000"},{"#text":"","from":"1150632000","to":"1151236800"},{"#text":"","from":"1151236800","to":"1151841600"},{"#text":"","from":"1151841600","to":"1152446400"},{"#text":"","from":"1152446400","to":"1153051200"},{"#text":"","from":"1153051200","to":"1153656000"},{"#text":"","from":"1153656000","to":"1154260800"},{"#text":"","from":"1154260800","to":"1154865600"},{"#text":"","from":"1154865600","to":"1155470400"},{"#text":"","from":"1155470400","to":"1156075200"},{"#text":"","from":"1156075200","to":"1156680000"},{"#text":"","from":"1156680000","to":"1157284800"},{"#text":"","from":"1157284800","to":"1157889600"},{"#text":"","from":"1157889600","to":"1158494400"},{"#text":"","from":"1158494400","to":"1159099200"},{"#text":"","from":"1159099200","to":"1159704000"},{"#text":"","from":"1159704000","to":"1160308800"},{"#text":"","from":"1160308800","to":"1160913600"},{"#text":"","from":"1160913600","to":"1161518400"},{"#text":"","from":"1161518400","to":"1162123200"},{"#text":"","from":"1162123200","to":"1162728000"},{"#text":"","from":"1162728000","to":"1163332800"},{"#text":"","from":"1163332800","to":"1163937600"},{"#text":"","from":"1163937600","to":"1164542400"},{"#text":"","from":"1164542400","to":"1165147200"},{"#text":"","from":"1165147200","to":"1165752000"},{"#text":"","from":"1165752000","to":"1166356800"},{"#text":"","from":"1166356800","to":"1166961600"},{"#text":"","from":"1166961600","to":"1167566400"},{"#text":"","from":"1167566400","to":"1168171200"},{"#text":"","from":"1168171200","to":"1168776000"},{"#text":"","from":"1168776000","to":"1169380800"},{"#text":"","from":"1169380800","to":"1169985600"},{"#text":"","from":"1169985600","to":"1170590400"},{"#text":"","from":"1170590400","to":"1171195200"},{"#text":"","from":"1171195200","to":"1171800000"},{"#text":"","from":"1171800000","to":"1172404800"},{"#text":"","from":"1172404800","to":"1173009600"},{"#text":"","from":"1173009600","to":"1173614400"},{"#text":"","from":"1173614400","to":"1174219200"},{"#text":"","from":"1174219200","to":"1174824000"},{"#text":"","from":"1174824000","to":"1175428800"},{"#text":"","from":"1175428800","to":"1176033600"},{"#text":"","from":"1176033600","to":"1176638400"},{"#text":"","from":"1176638400","to":"1177243200"},{"#text":"","from":"1177243200","to":"1177848000"},{"#text":"","from":"1177848000","to":"1178452800"},{"#text":"","from":"1178452800","to":"1179057600"},{"#text":"","from":"1179057600","to":"1179662400"},{"#text":"","from":"1179662400","to":"1180267200"},{"#text":"","from":"1180267200","to":"1180872000"},{"#text":"","from":"1180872000","to":"1181476800"},{"#text":"","from":"1181476800","to":"1182081600"},{"#text":"","from":"1182081600","to":"1182686400"},{"#text":"","from":"1182686400","to":"1183291200"},{"#text":"","from":"1183291200","to":"1183896000"},{"#text":"","from":"1183896000","to":"1184500800"},{"#text":"","from":"1184500800","to":"1185105600"},{"#text":"","from":"1185105600","to":"1185710400"},{"#text":"","from":"1185710400","to":"1186315200"},{"#text":"","from":"1186315200","to":"1186920000"},{"#text":"","from":"1186920000","to":"1187524800"},{"#text":"","from":"1187524800","to":"1188129600"},{"#text":"","from":"1188129600","to":"1188734400"},{"#text":"","from":"1188734400","to":"1189339200"},{"#text":"","from":"1189339200","to":"1189944000"},{"#text":"","from":"1189944000","to":"1190548800"},{"#text":"","from":"1190548800","to":"1191153600"},{"#text":"","from":"1191153600","to":"1191758400"},{"#text":"","from":"1191758400","to":"1192363200"},{"#text":"","from":"1192363200","to":"1192968000"},{"#text":"","from":"1192968000","to":"1193572800"},{"#text":"","from":"1193572800","to":"1194177600"},{"#text":"","from":"1194177600","to":"1194782400"},{"#text":"","from":"1194782400","to":"1195387200"},{"#text":"","from":"1195387200","to":"1195992000"},{"#text":"","from":"1195992000","to":"1196596800"},{"#text":"","from":"1196596800","to":"1197201600"},{"#text":"","from":"1197201600","to":"1197806400"},{"#text":"","from":"1197806400","to":"1198411200"},{"#text":"","from":"1198411200","to":"1199016000"},{"#text":"","from":"1199016000","to":"1199620800"},{"#text":"","from":"1199620800","to":"1200225600"},{"#text":"","from":"1200225600","to":"1200830400"},{"#text":"","from":"1200830400","to":"1201435200"},{"#text":"","from":"1201435200","to":"1202040000"},{"#text":"","from":"1202040000","to":"1202644800"},{"#text":"","from":"1202644800","to":"1203249600"},{"#text":"","from":"1203249600","to":"1203854400"},{"#text":"","from":"1203854400","to":"1204459200"},{"#text":"","from":"1204459200","to":"1205064000"},{"#text":"","from":"1205064000","to":"1205668800"},{"#text":"","from":"1205668800","to":"1206273600"},{"#text":"","from":"1206273600","to":"1206878400"},{"#text":"","from":"1206878400","to":"1207483200"},{"#text":"","from":"1207483200","to":"1208088000"},{"#text":"","from":"1208088000","to":"1208692800"},{"#text":"","from":"1208692800","to":"1209297600"},{"#text":"","from":"1209297600","to":"1209902400"},{"#text":"","from":"1209902400","to":"1210507200"},{"#text":"","from":"1210507200","to":"1211112000"},{"#text":"","from":"1211112000","to":"1211716800"},{"#text":"","from":"1211716800","to":"1212321600"},{"#text":"","from":"1212321600","to":"1212926400"},{"#text":"","from":"1212926400","to":"1213531200"},{"#text":"","from":"1213531200","to":"1214136000"},{"#text":"","from":"1214136000","to":"1214740800"},{"#text":"","from":"1214740800","to":"1215345600"},{"#text":"","from":"1215345600","to":"1215950400"},{"#text":"","from":"1215950400","to":"1216555200"},{"#text":"","from":"1216555200","to":"1217160000"},{"#text":"","from":"1217160000","to":"1217764800"},{"#text":"","from":"1217764800","to":"1218369600"},{"#text":"","from":"1218369600","to":"1218974400"},{"#text":"","from":"1218974400","to":"1219579200"},{"#text":"","from":"1219579200","to":"1220184000"},{"#text":"","from":"1220184000","to":"1220788800"},{"#text":"","from":"1220788800","to":"1221393600"},{"#text":"","from":"1221393600","to":"1221998400"},{"#text":"","from":"1221998400","to":"1222603200"},{"#text":"","from":"1222603200","to":"1223208000"},{"#text":"","from":"1223208000","to":"1223812800"},{"#text":"","from":"1223812800","to":"1224417600"},{"#text":"","from":"1224417600","to":"1225022400"},{"#text":"","from":"1225022400","to":"1225627200"},{"#text":"","from":"1225627200","to":"1226232000"},{"#text":"","from":"1226232000","to":"1226836800"},{"#text":"","from":"1226836800","to":"1227441600"},{"#text":"","from":"1227441600","to":"1228046400"},{"#text":"","from":"1228046400","to":"1228651200"},{"#text":"","from":"1228651200","to":"1229256000"},{"#text":"","from":"1229256000","to":"1229860800"},{"#text":"","from":"1229860800","to":"1230465600"},{"#text":"","from":"1230465600","to":"1231070400"},{"#text":"","from":"1231070400","to":"1231675200"},{"#text":"","from":"1231675200","to":"1232280000"},{"#text":"","from":"1232280000","to":"1232884800"},{"#text":"","from":"1232884800","to":"1233489600"},{"#text":"","from":"1233489600","to":"1234094400"},{"#text":"","from":"1234094400","to":"1234699200"},{"#text":"","from":"1234699200","to":"1235304000"},{"#text":"","from":"1235304000","to":"1235908800"},{"#text":"","from":"1235908800","to":"1236513600"},{"#text":"","from":"1236513600","to":"1237118400"},{"#text":"","from":"1237118400","to":"1237723200"},{"#text":"","from":"1237723200","to":"1238328000"},{"#text":"","from":"1238328000","to":"1238932800"},{"#text":"","from":"1238932800","to":"1239537600"},{"#text":"","from":"1239537600","to":"1240142400"},{"#text":"","from":"1240142400","to":"1240747200"},{"#text":"","from":"1240747200","to":"1241352000"},{"#text":"","from":"1241352000","to":"1241956800"},{"#text":"","from":"1241956800","to":"1242561600"},{"#text":"","from":"1242561600","to":"1243166400"},{"#text":"","from":"1243166400","to":"1243771200"},{"#text":"","from":"1243771200","to":"1244376000"},{"#text":"","from":"1244376000","to":"1244980800"},{"#text":"","from":"1244980800","to":"1245585600"},{"#text":"","from":"1245585600","to":"1246190400"},{"#text":"","from":"1246190400","to":"1246795200"},{"#text":"","from":"1246795200","to":"1247400000"},{"#text":"","from":"1247400000","to":"1248004800"},{"#text":"","from":"1248004800","to":"1248609600"},{"#text":"","from":"1248609600","to":"1249214400"},{"#text":"","from":"1249214400","to":"1249819200"},{"#text":"","from":"1249819200","to":"1250424000"},{"#text":"","from":"1250424000","to":"1251028800"},{"#text":"","from":"1251028800","to":"1251633600"},{"#text":"","from":"1251633600","to":"1252238400"},{"#text":"","from":"1252238400","to":"1252843200"},{"#text":"","from":"1252843200","to":"1253448000"},{"#text":"","from":"1253448000","to":"1254052800"},{"#text":"","from":"1254052800","to":"1254657600"},{"#text":"","from":"1254657600","to":"1255262400"},{"#text":"","from":"1255262400","to":"1255867200"},{"#text":"","from":"1255867200","to":"1256472000"},{"#text":"","from":"1256472000","to":"1257076800"},{"#text":"","from":"1257076800","to":"1257681600"},{"#text":"","from":"1257681600","to":"1258286400"},{"#text":"","from":"1258286400","to":"1258891200"},{"#text":"","from":"1258891200","to":"1259496000"},{"#text":"","from":"1259496000","to":"1260100800"},{"#text":"","from":"1260100800","to":"1260705600"},{"#text":"","from":"1260705600","to":"1261310400"},{"#text":"","from":"1261310400","to":"1261915200"},{"#text":"","from":"1261915200","to":"1262520000"},{"#text":"","from":"1262520000","to":"1263124800"},{"#text":"","from":"1263124800","to":"1263729600"},{"#text":"","from":"1263729600","to":"1264334400"},{"#text":"","from":"1264334400","to":"1264939200"},{"#text":"","from":"1264939200","to":"1265544000"},{"#text":"","from":"1265544000","to":"1266148800"},{"#text":"","from":"1266148800","to":"1266753600"},{"#text":"","from":"1266753600","to":"1267358400"},{"#text":"","from":"1267358400","to":"1267963200"},{"#text":"","from":"1267963200","to":"1268568000"},{"#text":"","from":"1268568000","to":"1269172800"},{"#text":"","from":"1269172800","to":"1269777600"},{"#text":"","from":"1269777600","to":"1270382400"},{"#text":"","from":"1270382400","to":"1270987200"},{"#text":"","from":"1270987200","to":"1271592000"},{"#text":"","from":"1271592000","to":"1272196800"},{"#text":"","from":"1272196800","to":"1272801600"},{"#text":"","from":"1272801600","to":"1273406400"},{"#text":"","from":"1273406400","to":"1274011200"},{"#text":"","from":"1274011200","to":"1274616000"},{"#text":"","from":"1274616000","to":"1275220800"},{"#text":"","from":"1275220800","to":"1275825600"},{"#text":"","from":"1275825600","to":"1276430400"},{"#text":"","from":"1276430400","to":"1277035200"},{"#text":"","from":"1277035200","to":"1277640000"},{"#text":"","from":"1277640000","to":"1278244800"},{"#text":"","from":"1278244800","to":"1278849600"},{"#text":"","from":"1278849600","to":"1279454400"},{"#text":"","from":"1279454400","to":"1280059200"},{"#text":"","from":"1280059200","to":"1280664000"},{"#text":"","from":"1280664000","to":"1281268800"},{"#text":"","from":"1281268800","to":"1281873600"},{"#text":"","from":"1281873600","to":"1282478400"},{"#text":"","from":"1282478400","to":"1283083200"},{"#text":"","from":"1283083200","to":"1283688000"},{"#text":"","from":"1283688000","to":"1284292800"},{"#text":"","from":"1284292800","to":"1284897600"},{"#text":"","from":"1284897600","to":"1285502400"},{"#text":"","from":"1285502400","to":"1286107200"},{"#text":"","from":"1286107200","to":"1286712000"},{"#text":"","from":"1286712000","to":"1287316800"},{"#text":"","from":"1287316800","to":"1287921600"},{"#text":"","from":"1287921600","to":"1288526400"},{"#text":"","from":"1288526400","to":"1289131200"},{"#text":"","from":"1289131200","to":"1289736000"},{"#text":"","from":"1289736000","to":"1290340800"},{"#text":"","from":"1290340800","to":"1290945600"},{"#text":"","from":"1290945600","to":"1291550400"},{"#text":"","from":"1291550400","to":"1292155200"},{"#text":"","from":"1292155200","to":"1292760000"},{"#text":"","from":"1292760000","to":"1293364800"},{"#text":"","from":"1293364800","to":"1293969600"},{"#text":"","from":"1293969600","to":"1294574400"},{"#text":"","from":"1294574400","to":"1295179200"},{"#text":"","from":"1295179200","to":"1295784000"},{"#text":"","from":"1295784000","to":"1296388800"},{"#text":"","from":"1296388800","to":"1296993600"},{"#text":"","from":"1296993600","to":"1297598400"},{"#text":"","from":"1297598400","to":"1298203200"},{"#text":"","from":"1298203200","to":"1298808000"},{"#text":"","from":"1298808000","to":"1299412800"},{"#text":"","from":"1299412800","to":"1300017600"},{"#text":"","from":"1300017600","to":"1300622400"},{"#text":"","from":"1300622400","to":"1301227200"},{"#text":"","from":"1301227200","to":"1301832000"},{"#text":"","from":"1301832000","to":"1302436800"},{"#text":"","from":"1302436800","to":"1303041600"},{"#text":"","from":"1303041600","to":"1303646400"},{"#text":"","from":"1303646400","to":"1304251200"},{"#text":"","from":"1304251200","to":"1304856000"},{"#text":"","from":"1304856000","to":"1305460800"},{"#text":"","from":"1305460800","to":"1306065600"},{"#text":"","from":"1306065600","to":"1306670400"},{"#text":"","from":"1306670400","to":"1307275200"},{"#text":"","from":"1307275200","to":"1307880000"},{"#text":"","from":"1307880000","to":"1308484800"},{"#text":"","from":"1308484800","to":"1309089600"},{"#text":"","from":"1309089600","to":"1309694400"},{"#text":"","from":"1309694400","to":"1310299200"},{"#text":"","from":"1310299200","to":"1310904000"},{"#text":"","from":"1310904000","to":"1311508800"},{"#text":"","from":"1311508800","to":"1312113600"},{"#text":"","from":"1312113600","to":"1312718400"},{"#text":"","from":"1312718400","to":"1313323200"},{"#text":"","from":"1313323200","to":"1313928000"},{"#text":"","from":"1313928000","to":"1314532800"},{"#text":"","from":"1314532800","to":"1315137600"},{"#text":"","from":"1315137600","to":"1315742400"},{"#text":"","from":"1315742400","to":"1316347200"},{"#text":"","from":"1316347200","to":"1316952000"},{"#text":"","from":"1316952000","to":"1317556800"},{"#text":"","from":"1317556800","to":"1318161600"},{"#text":"","from":"1318161600","to":"1318766400"},{"#text":"","from":"1318766400","to":"1319371200"},{"#text":"","from":"1319371200","to":"1319976000"},{"#text":"","from":"1319976000","to":"1320580800"},{"#text":"","from":"1320580800","to":"1321185600"},{"#text":"","from":"1321185600","to":"1321790400"},{"#text":"","from":"1321790400","to":"1322395200"},{"#text":"","from":"1322395200","to":"1323000000"},{"#text":"","from":"1323000000","to":"1323604800"},{"#text":"","from":"1323604800","to":"1324209600"},{"#text":"","from":"1324209600","to":"1324814400"},{"#text":"","from":"1324814400","to":"1325419200"},{"#text":"","from":"1325419200","to":"1326024000"},{"#text":"","from":"1326024000","to":"1326628800"},{"#text":"","from":"1326628800","to":"1327233600"},{"#text":"","from":"1327233600","to":"1327838400"},{"#text":"","from":"1327838400","to":"1328443200"},{"#text":"","from":"1328443200","to":"1329048000"},{"#text":"","from":"1329048000","to":"1329652800"},{"#text":"","from":"1329652800","to":"1330257600"},{"#text":"","from":"1330257600","to":"1330862400"},{"#text":"","from":"1330862400","to":"1331467200"},{"#text":"","from":"1331467200","to":"1332072000"},{"#text":"","from":"1332072000","to":"1332676800"},{"#text":"","from":"1332676800","to":"1333281600"},{"#text":"","from":"1333281600","to":"1333886400"},{"#text":"","from":"1333886400","to":"1334491200"},{"#text":"","from":"1334491200","to":"1335096000"},{"#text":"","from":"1335096000","to":"1335700800"},{"#text":"","from":"1335700800","to":"1336305600"},{"#text":"","from":"1336305600","to":"1336910400"},{"#text":"","from":"1336910400","to":"1337515200"},{"#text":"","from":"1337515200","to":"1338120000"},{"#text":"","from":"1338120000","to":"1338724800"},{"#text":"","from":"1338724800","to":"1339329600"},{"#text":"","from":"1339329600","to":"1339934400"},{"#text":"","from":"1339934400","to":"1340539200"},{"#text":"","from":"1340539200","to":"1341144000"},{"#text":"","from":"1341144000","to":"1341748800"},{"#text":"","from":"1341748800","to":"1342353600"},{"#text":"","from":"1342353600","to":"1342958400"},{"#text":"","from":"1342958400","to":"1343563200"},{"#text":"","from":"1343563200","to":"1344168000"},{"#text":"","from":"1344168000","to":"1344772800"},{"#text":"","from":"1344772800","to":"1345377600"},{"#text":"","from":"1345377600","to":"1345982400"},{"#text":"","from":"1345982400","to":"1346587200"},{"#text":"","from":"1346587200","to":"1347192000"},{"#text":"","from":"1347192000","to":"1347796800"},{"#text":"","from":"1347796800","to":"1348401600"},{"#text":"","from":"1348401600","to":"1349006400"},{"#text":"","from":"1349006400","to":"1349611200"},{"#text":"","from":"1349611200","to":"1350216000"},{"#text":"","from":"1350216000","to":"1350820800"},{"#text":"","from":"1350820800","to":"1351425600"},{"#text":"","from":"1351425600","to":"1352030400"},{"#text":"","from":"1352030400","to":"1352635200"},{"#text":"","from":"1352635200","to":"1353240000"},{"#text":"","from":"1353240000","to":"1353844800"},{"#text":"","from":"1353844800","to":"1354449600"},{"#text":"","from":"1354449600","to":"1355054400"},{"#text":"","from":"1355054400","to":"1355659200"},{"#text":"","from":"1355659200","to":"1356264000"},{"#text":"","from":"1356264000","to":"1356868800"},{"#text":"","from":"1356868800","to":"1357473600"},{"#text":"","from":"1357473600","to":"1358078400"},{"#text":"","from":"1358078400","to":"1358683200"},{"#text":"","from":"1358683200","to":"1359288000"},{"#text":"","from":"1359288000","to":"1359892800"},{"#text":"","from":"1359892800","to":"1360497600"},{"#text":"","from":"1360497600","to":"1361102400"},{"#text":"","from":"1361102400","to":"1361707200"},{"#text":"","from":"1361707200","to":"1362312000"},{"#text":"","from":"1362312000","to":"1362916800"},{"#text":"","from":"1362916800","to":"1363521600"},{"#text":"","from":"1363521600","to":"1364126400"},{"#text":"","from":"1364126400","to":"1364731200"},{"#text":"","from":"1364731200","to":"1365336000"},{"#text":"","from":"1365336000","to":"1365940800"},{"#text":"","from":"1365940800","to":"1366545600"},{"#text":"","from":"1366545600","to":"1367150400"},{"#text":"","from":"1367150400","to":"1367755200"},{"#text":"","from":"1367755200","to":"1368360000"},{"#text":"","from":"1368360000","to":"1368964800"},{"#text":"","from":"1368964800","to":"1369569600"},{"#text":"","from":"1369569600","to":"1370174400"},{"#text":"","from":"1370174400","to":"1370779200"},{"#text":"","from":"1370779200","to":"1371384000"},{"#text":"","from":"1371384000","to":"1371988800"},{"#text":"","from":"1371988800","to":"1372593600"},{"#text":"","from":"1372593600","to":"1373198400"},{"#text":"","from":"1373198400","to":"1373803200"},{"#text":"","from":"1373803200","to":"1374408000"},{"#text":"","from":"1374408000","to":"1375012800"},{"#text":"","from":"1375012800","to":"1375617600"},{"#text":"","from":"1375617600","to":"1376222400"},{"#text":"","from":"1376222400","to":"1376827200"},{"#text":"","from":"1376827200","to":"1377432000"},{"#text":"","from":"1377432000","to":"1378036800"},{"#text":"","from":"1378036800","to":"1378641600"},{"#text":"","from":"1378641600","to":"1379246400"},{"#text":"","from":"1379246400","to":"1379851200"},{"#text":"","from":"1379851200","to":"1380456000"},{"#text":"","from":"1380456000","to":"1381060800"},{"#text":"","from":"1381060800","to":"1381665600"},{"#text":"","from":"1381665600","to":"1382270400"},{"#text":"","from":"1382270400","to":"1382875200"},{"#text":"","from":"1382875200","to":"1383480000"},{"#text":"","from":"1383480000","to":"1384084800"},{"#text":"","from":"1384084800","to":"1384689600"},{"#text":"","from":"1384689600","to":"1385294400"},{"#text":"","from":"1385294400","to":"1385899200"},{"#text":"","from":"1385899200","to":"1386504000"},{"#text":"","from":"1386504000","to":"1387108800"},{"#text":"","from":"1387108800","to":"1387713600"},{"#text":"","from":"1387713600","to":"1388318400"},{"#text":"","from":"1388318400","to":"1388923200"},{"#text":"","from":"1388923200","to":"1389528000"},{"#text":"","from":"1389528000","to":"1390132800"},{"#text":"","from":"1390132800","to":"1390737600"},{"#text":"","from":"1390737600","to":"1391342400"},{"#text":"","from":"1391342400","to":"1391947200"},{"#text":"","from":"1391947200","to":"1392552000"},{"#text":"","from":"1392552000","to":"1393156800"},{"#text":"","from":"1393156800","to":"1393761600"},{"#text":"","from":"1393761600","to":"1394366400"},{"#text":"","from":"1394366400","to":"1394971200"},{"#text":"","from":"1394971200","to":"1395576000"},{"#text":"","from":"1395576000","to":"1396180800"},{"#text":"","from":"1396180800","to":"1396785600"},{"#text":"","from":"1396785600","to":"1397390400"},{"#text":"","from":"1397390400","to":"1397995200"},{"#text":"","from":"1397995200","to":"1398600000"},{"#text":"","from":"1398600000","to":"1399204800"},{"#text":"","from":"1399204800","to":"1399809600"},{"#text":"","from":"1399809600","to":"1400414400"},{"#text":"","from":"1400414400","to":"1401019200"},{"#text":"","from":"1401019200","to":"1401624000"},{"#text":"","from":"1401624000","to":"1402228800"},{"#text":"","from":"1402228800","to":"1402833600"},{"#text":"","from":"1402833600","to":"1403438400"},{"#text":"","from":"1403438400","to":"1404043200"},{"#text":"","from":"1404043200","to":"1404648000"},{"#text":"","from":"1404648000","to":"1405252800"},{"#text":"","from":"1405252800","to":"1405857600"},{"#text":"","from":"1405857600","to":"1406462400"},{"#text":"","from":"1406462400","to":"1407067200"},{"#text":"","from":"1407067200","to":"1407672000"},{"#text":"","from":"1407672000","to":"1408276800"},{"#text":"","from":"1408276800","to":"1408881600"},{"#text":"","from":"1408881600","to":"1409486400"},{"#text":"","from":"1409486400","to":"1410091200"},{"#text":"","from":"1410091200","to":"1410696000"},{"#text":"","from":"1410696000","to":"1411300800"},{"#text":"","from":"1411300800","to":"1411905600"},{"#text":"","from":"1411905600","to":"1412510400"},{"#text":"","from":"1412510400","to":"1413115200"},{"#text":"","from":"1413115200","to":"1413720000"},{"#text":"","from":"1413720000","to":"1414324800"},{"#text":"","from":"1414324800","to":"1414929600"},{"#text":"","from":"1414929600","to":"1415534400"},{"#text":"","from":"1415534400","to":"1416139200"},{"#text":"","from":"1416139200","to":"1416744000"},{"#text":"","from":"1416744000","to":"1417348800"},{"#text":"","from":"1417348800","to":"1417953600"},{"#text":"","from":"1417953600","to":"1418558400"},{"#text":"","from":"1418558400","to":"1419163200"},{"#text":"","from":"1419163200","to":"1419768000"},{"#text":"","from":"1419768000","to":"1420372800"},{"#text":"","from":"1420372800","to":"1420977600"},{"#text":"","from":"1420977600","to":"1421582400"},{"#text":"","from":"1421582400","to":"1422187200"},{"#text":"","from":"1422187200","to":"1422792000"},{"#text":"","from":"1422792000","to":"1423396800"},{"#text":"","from":"1423396800","to":"1424001600"},{"#text":"","from":"1424001600","to":"1424606400"},{"#text":"","from":"1424606400","to":"1425211200"},{"#text":"","from":"1425211200","to":"1425816000"},{"#text":"","from":"1425816000","to":"1426420800"},{"#text":"","from":"1426420800","to":"1427025600"},{"#text":"","from":"1427025600","to":"1427630400"},{"#text":"","from":"1427630400","to":"1428235200"},{"#text":"","from":"1428235200","to":"1428840000"},{"#text":"","from":"1428840000","to":"1429444800"},{"#text":"","from":"1429444800","to":"1430049600"},{"#text":"","from":"1430049600","to":"1430654400"},{"#text":"","from":"1430654400","to":"1431259200"},{"#text":"","from":"1431259200","to":"1431864000"},{"#text":"","from":"1431864000","to":"1432468800"},{"#text":"","from":"1432468800","to":"1433073600"},{"#text":"","from":"1433073600","to":"1433678400"},{"#text":"","from":"1433678400","to":"1434283200"},{"#text":"","from":"1434283200","to":"1434888000"},{"#text":"","from":"1434888000","to":"1435492800"},{"#text":"","from":"1435492800","to":"1436097600"},{"#text":"","from":"1436097600","to":"1436702400"},{"#text":"","from":"1436702400","to":"1437307200"},{"#text":"","from":"1437307200","to":"1437912000"},{"#text":"","from":"1437912000","to":"1438516800"},{"#text":"","from":"1438516800","to":"1439121600"},{"#text":"","from":"1439121600","to":"1439726400"},{"#text":"","from":"1439726400","to":"1440331200"},{"#text":"","from":"1440331200","to":"1440936000"},{"#text":"","from":"1440936000","to":"1441540800"},{"#text":"","from":"1441540800","to":"1442145600"},{"#text":"","from":"1442145600","to":"1442750400"},{"#text":"","from":"1442750400","to":"1443355200"},{"#text":"","from":"1443355200","to":"1443960000"},{"#text":"","from":"1443960000","to":"1444564800"},{"#text":"","from":"1444564800","to":"1445169600"},{"#text":"","from":"1445169600","to":"1445774400"},{"#text":"","from":"1445774400","to":"1446379200"},{"#text":"","from":"1446379200","to":"1446984000"},{"#text":"","from":"1446984000","to":"1447588800"},{"#text":"","from":"1447588800","to":"1448193600"},{"#text":"","from":"1448193600","to":"1448798400"},{"#text":"","from":"1448798400","to":"1449403200"},{"#text":"","from":"1449403200","to":"1450008000"},{"#text":"","from":"1450008000","to":"1450612800"},{"#text":"","from":"1450612800","to":"1451217600"},{"#text":"","from":"1451217600","to":"1451822400"},{"#text":"","from":"1451822400","to":"1452427200"},{"#text":"","from":"1452427200","to":"1453032000"},{"#text":"","from":"1453032000","to":"1453636800"},{"#text":"","from":"1453636800","to":"1454241600"},{"#text":"","from":"1454241600","to":"1454846400"},{"#text":"","from":"1454846400","to":"1455451200"},{"#text":"","from":"1455451200","to":"1456056000"},{"#text":"","from":"1456056000","to":"1456660800"},{"#text":"","from":"1456660800","to":"1457265600"},{"#text":"","from":"1457265600","to":"1457870400"},{"#text":"","from":"1457870400","to":"1458475200"},{"#text":"","from":"1458475200","to":"1459080000"},{"#text":"","from":"1459080000","to":"1459684800"},{"#text":"","from":"1459684800","to":"1460289600"},{"#text":"","from":"1460289600","to":"1460894400"},{"#text":"","from":"1460894400","to":"1461499200"},{"#text":"","from":"1461499200","to":"1462104000"},{"#text":"","from":"1462104000","to":"1462708800"},{"#text":"","from":"1462708800","to":"1463313600"},{"#text":"","from":"1463313600","to":"1463918400"},{"#text":"","from":"1463918400","to":"1464523200"},{"#text":"","from":"1464523200","to":"1465128000"},{"#text":"","from":"1465128000","to":"1465732800"},{"#text":"","from":"1465732800","to":"1466337600"},{"#text":"","from":"1466337600","to":"1466942400"},{"#text":"","from":"1466942400","to":"1467547200"},{"#text":"","from":"1467547200","to":"1468152000"},{"#text":"","from":"1468152000","to":"1468756800"},{"#text":"","from":"1468756800","to":"1469361600"},{"#text":"","from":"1469361600","to":"1469966400"},{"#text":"","from":"1469966400","to":"1470571200"},{"#text":"","from":"1470571200","to":"1471176000"},{"#text":"","from":"1471176000","to":"1471780800"},{"#text":"","from":"1471780800","to":"1472385600"},{"#text":"","from":"1472385600","to":"1472990400"},{"#text":"","from":"1472990400","to":"1473595200"},{"#text":"","from":"1473595200","to":"1474200000"},{"#text":"","from":"1474200000","to":"1474804800"},{"#text":"","from":"1474804800","to":"1475409600"},{"#text":"","from":"1475409600","to":"1476014400"},{"#text":"","from":"1476014400","to":"1476619200"},{"#text":"","from":"1476619200","to":"1477224000"},{"#text":"","from":"1477224000","to":"1477828800"},{"#text":"","from":"1477828800","to":"1478433600"},{"#text":"","from":"1478433600","to":"1479038400"},{"#text":"","from":"1479038400","to":"1479643200"},{"#text":"","from":"1479643200","to":"1480248000"},{"#text":"","from":"1480248000","to":"1480852800"},{"#text":"","from":"1480852800","to":"1481457600"},{"#text":"","from":"1481457600","to":"1482062400"},{"#text":"","from":"1482062400","to":"1482667200"},{"#text":"","from":"1482667200","to":"1483272000"},{"#text":"","from":"1483272000","to":"1483876800"},{"#text":"","from":"1483876800","to":"1484481600"},{"#text":"","from":"1484481600","to":"1485086400"},{"#text":"","from":"1485086400","to":"1485691200"},{"#text":"","from":"1485691200","to":"1486296000"},{"#text":"","from":"1486296000","to":"1486900800"},{"#text":"","from":"1486900800","to":"1487505600"},{"#text":"","from":"1487505600","to":"1488110400"},{"#text":"","from":"1488110400","to":"1488715200"},{"#text":"","from":"1488715200","to":"1489320000"},{"#text":"","from":"1489320000","to":"1489924800"},{"#text":"","from":"1489924800","to":"1490529600"},{"#text":"","from":"1490529600","to":"1491134400"},{"#text":"","from":"1491134400","to":"1491739200"},{"#text":"","from":"1491739200","to":"1492344000"},{"#text":"","from":"1492344000","to":"1492948800"},{"#text":"","from":"1492948800","to":"1493553600"},{"#text":"","from":"1493553600","to":"1494158400"},{"#text":"","from":"1494158400","to":"1494763200"},{"#text":"","from":"1494763200","to":"1495368000"},{"#text":"","from":"1495368000","to":"1495972800"},{"#text":"","from":"1495972800","to":"1496577600"},{"#text":"","from":"1496577600","to":"1497182400"},{"#text":"","from":"1497182400","to":"1497787200"},{"#text":"","from":"1497787200","to":"1498392000"},{"#text":"","from":"1498392000","to":"1498996800"},{"#text":"","from":"1498996800","to":"1499601600"},{"#text":"","from":"1499601600","to":"1500206400"},{"#text":"","from":"1500206400","to":"1500811200"},{"#text":"","from":"1500811200","to":"1501416000"},{"#text":"","from":"1501416000","to":"1502020800"},{"#text":"","from":"1502020800","to":"1502625600"},{"#text":"","from":"1502625600","to":"1503230400"},{"#text":"","from":"1503230400","to":"1503835200"},{"#text":"","from":"1503835200","to":"1504440000"},{"#text":"","from":"1504440000","to":"1505044800"},{"#text":"","from":"1505044800","to":"1505649600"},{"#text":"","from":"1505649600","to":"1506254400"},{"#text":"","from":"1506254400","to":"1506859200"},{"#text":"","from":"1506859200","to":"1507464000"},{"#text":"","from":"1507464000","to":"1508068800"},{"#text":"","from":"1508068800","to":"1508673600"},{"#text":"","from":"1508673600","to":"1509278400"},{"#text":"","from":"1509278400","to":"1509883200"},{"#text":"","from":"1509883200","to":"1510488000"},{"#text":"","from":"1510488000","to":"1511092800"},{"#text":"","from":"1511092800","to":"1511697600"},{"#text":"","from":"1511697600","to":"1512302400"},{"#text":"","from":"1512302400","to":"1512907200"},{"#text":"","from":"1512907200","to":"1513512000"},{"#text":"","from":"1513512000","to":"1514116800"},{"#text":"","from":"1514116800","to":"1514721600"},{"#text":"","from":"1514721600","to":"1515326400"},{"#text":"","from":"1515326400","to":"1515931200"},{"#text":"","from":"1515931200","to":"1516536000"},{"#text":"","from":"1516536000","to":"1517140800"},{"#text":"","from":"1517140800","to":"1517745600"},{"#text":"","from":"1517745600","to":"1518350400"},{"#text":"","from":"1518350400","to":"1518955200"},{"#text":"","from":"1518955200","to":"1519560000"},{"#text":"","from":"1519560000","to":"1520164800"},{"#text":"","from":"1520164800","to":"1520769600"},{"#text":"","from":"1520769600","to":"1521374400"},{"#text":"","from":"1521374400","to":"1521979200"},{"#text":"","from":"1521979200","to":"1522584000"},{"#text":"","from":"1522584000","to":"1523188800"},{"#text":"","from":"1523188800","to":"1523793600"},{"#text":"","from":"1523793600","to":"1524398400"},{"#text":"","from":"1524398400","to":"1525003200"},{"#text":"","from":"1525003200","to":"1525608000"},{"#text":"","from":"1525608000","to":"1526212800"},{"#text":"","from":"1526212800","to":"1526817600"},{"#text":"","from":"1526817600","to":"1527422400"},{"#text":"","from":"1527422400","to":"1528027200"},{"#text":"","from":"1528027200","to":"1528632000"},{"#text":"","from":"1528632000","to":"1529236800"},{"#text":"","from":"1529236800","to":"1529841600"},{"#text":"","from":"1529841600","to":"1530446400"},{"#text":"","from":"1530446400","to":"1531051200"},{"#text":"","from":"1531051200","to":"1531656000"},{"#text":"","from":"1531656000","to":"1532260800"},{"#text":"","from":"1532260800","to":"1532865600"},{"#text":"","from":"1532865600","to":"1533470400"},{"#text":"","from":"1533470400","to":"1534075200"},{"#text":"","from":"1534075200","to":"1534680000"},{"#text":"","from":"1534680000","to":"1535284800"},{"#text":"","from":"1535284800","to":"1535889600"},{"#text":"","from":"1535889600","to":"1536494400"},{"#text":"","from":"1536494400","to":"1537099200"},{"#text":"","from":"1537099200","to":"1537704000"},{"#text":"","from":"1537704000","to":"1538308800"},{"#text":"","from":"1538308800","to":"1538913600"},{"#text":"","from":"1538913600","to":"1539518400"},{"#text":"","from":"1539518400","to":"1540123200"},{"#text":"","from":"1540123200","to":"1540728000"},{"#text":"","from":"1540728000","to":"1541332800"},{"#text":"","from":"1541332800","to":"1541937600"},{"#text":"","from":"1541937600","to":"1542542400"},{"#text":"","from":"1542542400","to":"1543147200"},{"#text":"","from":"1543147200","to":"1543752000"},{"#text":"","from":"1543752000","to":"1544356800"},{"#text":"","from":"1544356800","to":"1544961600"},{"#text":"","from":"1544961600","to":"1545566400"},{"#text":"","from":"1545566400","to":"1546171200"},{"#text":"","from":"1546171200","to":"1546776000"},{"#text":"","from":"1546776000","to":"1547380800"},{"#text":"","from":"1547380800","to":"1547985600"},{"#text":"","from":"1547985600","to":"1548590400"},{"#text":"","from":"1548590400","to":"1549195200"},{"#text":"","from":"1549195200","to":"1549800000"},{"#text":"","from":"1549800000","to":"1550404800"},{"#text":"","from":"1550404800","to":"1551009600"},{"#text":"","from":"1551009600","to":"1551614400"},{"#text":"","from":"1551614400","to":"1552219200"},{"#text":"","from":"1552219200","to":"1552824000"},{"#text":"","from":"1552824000","to":"1553428800"},{"#text":"","from":"1553428800","to":"1554033600"},{"#text":"","from":"1554033600","to":"1554638400"},{"#text":"","from":"1554638400","to":"1555243200"},{"#text":"","from":"1555243200","to":"1555848000"},{"#text":"","from":"1555848000","to":"1556452800"},{"#text":"","from":"1556452800","to":"1557057600"},{"#text":"","from":"1557057600","to":"1557662400"},{"#text":"","from":"1557662400","to":"1558267200"},{"#text":"","from":"1558267200","to":"1558872000"},{"#text":"","from":"1558872000","to":"1559476800"},{"#text":"","from":"1559476800","to":"1560081600"},{"#text":"","from":"1560081600","to":"1560686400"},{"#text":"","from":"1560686400","to":"1561291200"},{"#text":"","from":"1561291200","to":"1561896000"},{"#text":"","from":"1561896000","to":"1562500800"},{"#text":"","from":"1562500800","to":"1563105600"},{"#text":"","from":"1563105600","to":"1563710400"},{"#text":"","from":"1563710400","to":"1564315200"},{"#text":"","from":"1564315200","to":"1564920000"},{"#text":"","from":"1564920000","to":"1565524800"},{"#text":"","from":"1565524800","to":"1566129600"},{"#text":"","from":"1566129600","to":"1566734400"},{"#text":"","from":"1566734400","to":"1567339200"},{"#text":"","from":"1567339200","to":"1567944000"},{"#text":"","from":"1567944000","to":"1568548800"},{"#text":"","from":"1568548800","to":"1569153600"},{"#text":"","from":"1569153600","to":"1569758400"},{"#text":"","from":"1569758400","to":"1570363200"},{"#text":"","from":"1570363200","to":"1570968000"},{"#text":"","from":"1570968000","to":"1571572800"},{"#text":"","from":"1571572800","to":"1572177600"},{"#text":"","from":"1572177600","to":"1572782400"},{"#text":"","from":"1572782400","to":"1573387200"},{"#text":"","from":"1573387200","to":"1573992000"},{"#text":"","from":"1573992000","to":"1574596800"},{"#text":"","from":"1574596800","to":"1575201600"},{"#text":"","from":"1575201600","to":"1575806400"},{"#text":"","from":"1575806400","to":"1576411200"},{"#text":"","from":"1576411200","to":"1577016000"},{"#text":"","from":"1577016000","to":"1577620800"},{"#text":"","from":"1577620800","to":"1578225600"},{"#text":"","from":"1578225600","to":"1578830400"},{"#text":"","from":"1578830400","to":"1579435200"},{"#text":"","from":"1579435200","to":"1580040000"},{"#text":"","from":"1580040000","to":"1580644800"},{"#text":"","from":"1580644800","to":"1581249600"},{"#text":"","from":"1581249600","to":"1581854400"},{"#text":"","from":"1581854400","to":"1582459200"},{"#text":"","from":"1582459200","to":"1583064000"},{"#text":"","from":"1583064000","to":"1583668800"},{"#text":"","from":"1583668800","to":"1584273600"},{"#text":"","from":"1584273600","to":"1584878400"},{"#text":"","from":"1584878400","to":"1585483200"},{"#text":"","from":"1585483200","to":"1586088000"},{"#text":"","from":"1586088000","to":"1586692800"},{"#text":"","from":"1586692800","to":"1587297600"},{"#text":"","from":"1587297600","to":"1587902400"},{"#text":"","from":"1587902400","to":"1588507200"},{"#text":"","from":"1588507200","to":"1589112000"},{"#text":"","from":"1589112000","to":"1589716800"},{"#text":"","from":"1589716800","to":"1590321600"},{"#text":"","from":"1590321600","to":"1590926400"},{"#text":"","from":"1590926400","to":"1591531200"},{"#text":"","from":"1591531200","to":"1592136000"},{"#text":"","from":"1592136000","to":"1592740800"},{"#text":"","from":"1592740800","to":"1593345600"},{"#text":"","from":"1593345600","to":"1593950400"},{"#text":"","from":"1593950400","to":"1594555200"}],"@attr":{"user":"ybsc"}}}
    """#

    static let user_getWeeklyChart_json = #"""
    {"weeklyalbumchart":{"album":[{"artist":{"mbid":"3165f5e0-44ff-446a-81d7-c09ec69661ae","#text":"PUP"},"@attr":{"rank":"1"},"mbid":"97f17e68-b106-450d-b6c4-68c50cb5b7d6","playcount":"22","name":"Live at The Electric Ballroom","url":"https:\/\/www.last.fm\/music\/PUP\/Live+at+The+Electric+Ballroom"},{"artist":{"mbid":"20b144e3-dd0e-4359-ae0c-0af7188c443b","#text":"CoVet"},"@attr":{"rank":"2"},"mbid":"0f6c2d5e-582d-4ea7-ad88-872079302806","playcount":"20","name":"technicolor","url":"https:\/\/www.last.fm\/music\/CoVet\/technicolor"},{"artist":{"mbid":"44cf61b8-5197-448a-b82b-cef6ee89fac5","#text":"Paramore"},"@attr":{"rank":"3"},"mbid":"0b2345b3-1984-4e96-b60f-427827b9716a","playcount":"17","name":"Paramore","url":"https:\/\/www.last.fm\/music\/Paramore\/Paramore"},{"artist":{"mbid":"24d48e0a-d9f5-4296-83fd-63973b07e837","#text":"Royal Coda"},"@attr":{"rank":"4"},"mbid":"df3f1aa8-286c-4c2e-8d8d-78204ec8108a","playcount":"16","name":"Royal Coda","url":"https:\/\/www.last.fm\/music\/Royal+Coda\/Royal+Coda"},{"artist":{"mbid":"6318e724-7e6b-4e41-a35b-080065077c80","#text":"Protest the Hero"},"@attr":{"rank":"5"},"mbid":"85ef7249-cc01-4fd3-b342-4c6faf2069c2","playcount":"13","name":"Palimpsest","url":"https:\/\/www.last.fm\/music\/Protest+the+Hero\/Palimpsest"},{"artist":{"mbid":"","#text":"Rise Against"},"@attr":{"rank":"6"},"mbid":"","playcount":"12","name":"Siren Song Of The Counter Cult","url":"https:\/\/www.last.fm\/music\/Rise+Against\/Siren+Song+Of+The+Counter+Cult"},{"artist":{"mbid":"e5b8c0f3-0752-4a76-987a-96098ce9d490","#text":"The Flatliners"},"@attr":{"rank":"7"},"mbid":"54d92d77-2bbb-46f0-91a8-43b2f17bac10","playcount":"12","name":"Dead Language","url":"https:\/\/www.last.fm\/music\/The+Flatliners\/Dead+Language"},{"artist":{"mbid":"8d79e950-1333-4a32-9fc1-af53d421abc4","#text":"A Static Lullaby"},"@attr":{"rank":"8"},"mbid":"8de202b8-ca05-4437-8d19-a8b7992cf823","playcount":"11","name":"Rattlesnake!","url":"https:\/\/www.last.fm\/music\/A+Static+Lullaby\/Rattlesnake!"},{"artist":{"mbid":"b9a2a9a6-7a40-48a6-bcb1-8eff5b89ad5b","#text":"Nada Surf"},"@attr":{"rank":"9"},"mbid":"17030cc9-7ec1-3c78-bee6-d225e9565a10","playcount":"11","name":"The Weight Is a Gift","url":"https:\/\/www.last.fm\/music\/Nada+Surf\/The+Weight+Is+a+Gift"},{"artist":{"mbid":"a66ebddc-ff04-46b8-820a-15c63e80dba1","#text":"Against Me!"},"@attr":{"rank":"10"},"mbid":"2f51a506-6f56-34a2-a44b-a0dba4122bf6","playcount":"10","name":"New Wave","url":"https:\/\/www.last.fm\/music\/Against+Me!\/New+Wave"},{"artist":{"mbid":"24d48e0a-d9f5-4296-83fd-63973b07e837","#text":"Royal Coda"},"@attr":{"rank":"11"},"mbid":"6f0f25b9-c98d-4fa1-be96-dcbdcba67a8e","playcount":"8","name":"Compassion","url":"https:\/\/www.last.fm\/music\/Royal+Coda\/Compassion"},{"artist":{"mbid":"","#text":"Against Me!"},"@attr":{"rank":"12"},"mbid":"","playcount":"4","name":"White Crosses [Limited Edition]","url":"https:\/\/www.last.fm\/music\/Against+Me!\/White+Crosses+%5BLimited+Edition%5D"},{"artist":{"mbid":"","#text":"Nova Charisma"},"@attr":{"rank":"13"},"mbid":"52d07148-b53d-4e9d-9ca9-eee11581c47e","playcount":"3","name":"Exposition I","url":"https:\/\/www.last.fm\/music\/Nova+Charisma\/Exposition+I"}],"@attr":{"user":"ybsc","from":"1593950400","to":"1594555200"}}}
    """#

    static let album_getInfo_json = #"""
    {"album":{"name":"Paramore","artist":"Paramore","mbid":"0b2345b3-1984-4e96-b60f-427827b9716a","url":"https://www.last.fm/music/Paramore/Paramore","image":[{"#text":"https://lastfm.freetls.fastly.net/i/u/34s/bebe11f4ddf3dee473b26c7e2d5c9ff6.png","size":"small"},{"#text":"https://lastfm.freetls.fastly.net/i/u/64s/bebe11f4ddf3dee473b26c7e2d5c9ff6.png","size":"medium"},{"#text":"https://lastfm.freetls.fastly.net/i/u/174s/bebe11f4ddf3dee473b26c7e2d5c9ff6.png","size":"large"},{"#text":"https://lastfm.freetls.fastly.net/i/u/300x300/bebe11f4ddf3dee473b26c7e2d5c9ff6.png","size":"extralarge"},{"#text":"https://lastfm.freetls.fastly.net/i/u/300x300/bebe11f4ddf3dee473b26c7e2d5c9ff6.png","size":"mega"},{"#text":"https://lastfm.freetls.fastly.net/i/u/300x300/bebe11f4ddf3dee473b26c7e2d5c9ff6.png","size":""}],"listeners":"511055","playcount":"20540069","userplaycount":"235","tracks":{"track":[{"name":"Fast in My Car","url":"https://www.last.fm/music/Paramore/_/Fast+in+My+Car","duration":"223","@attr":{"rank":"1"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Now","url":"https://www.last.fm/music/Paramore/_/Now","duration":"247","@attr":{"rank":"2"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Grow Up","url":"https://www.last.fm/music/Paramore/_/Grow+Up","duration":"231","@attr":{"rank":"3"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Daydreaming","url":"https://www.last.fm/music/Paramore/_/Daydreaming","duration":"271","@attr":{"rank":"4"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Interlude: Moving On","url":"https://www.last.fm/music/Paramore/_/Interlude:+Moving+On","duration":"90","@attr":{"rank":"5"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Ain't It Fun","url":"https://www.last.fm/music/Paramore/_/Ain%27t+It+Fun","duration":"297","@attr":{"rank":"6"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Part II","url":"https://www.last.fm/music/Paramore/_/Part+II","duration":"281","@attr":{"rank":"7"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Last Hope","url":"https://www.last.fm/music/Paramore/_/Last+Hope","duration":"310","@attr":{"rank":"8"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Still into You","url":"https://www.last.fm/music/Paramore/_/Still+into+You","duration":"216","@attr":{"rank":"9"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Anklebiters","url":"https://www.last.fm/music/Paramore/_/Anklebiters","duration":"138","@attr":{"rank":"10"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Interlude: Holiday","url":"https://www.last.fm/music/Paramore/_/Interlude:+Holiday","duration":"70","@attr":{"rank":"11"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Proof","url":"https://www.last.fm/music/Paramore/_/Proof","duration":"195","@attr":{"rank":"12"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Hate to See Your Heart Break","url":"https://www.last.fm/music/Paramore/_/Hate+to+See+Your+Heart+Break","duration":"309","@attr":{"rank":"13"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"(One of Those) Crazy Girls","url":"https://www.last.fm/music/Paramore/_/(One+of+Those)+Crazy+Girls","duration":"213","@attr":{"rank":"14"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Interlude: I'm Not Angry Anymore","url":"https://www.last.fm/music/Paramore/_/Interlude:+I%27m+Not+Angry+Anymore","duration":"53","@attr":{"rank":"15"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Be Alone","url":"https://www.last.fm/music/Paramore/_/Be+Alone","duration":"220","@attr":{"rank":"16"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}},{"name":"Future","url":"https://www.last.fm/music/Paramore/_/Future","duration":"473","@attr":{"rank":"17"},"streamable":{"#text":"0","fulltrack":"0"},"artist":{"name":"Paramore","mbid":"728ea90d-279b-4201-a8c4-597830883150","url":"https://www.last.fm/music/Paramore"}}]},"tags":{"tag":[{"name":"2013","url":"https://www.last.fm/tag/2013"},{"name":"alternative","url":"https://www.last.fm/tag/alternative"},{"name":"rock","url":"https://www.last.fm/tag/rock"},{"name":"pop punk","url":"https://www.last.fm/tag/pop+punk"},{"name":"albums I own","url":"https://www.last.fm/tag/albums+I+own"}]},"wiki":{"published":"18 Jan 2013, 17:35","summary":"Paramore is the band's self-titled fourth studio album, released on April 9, 2013 through Fueled by Ramen. It is their first album without co-founders Josh and Zac Farro. When asked about why the album is self-titled, Williams explained \"The self-titled aspect of the whole thing is definitely a statement. I feel like it's not only reintroducing the band to the world, but even to ourselves ... By the end of it, it felt like we're a new band.\" <a href=\"http://www.last.fm/music/Paramore/Paramore\">Read more on Last.fm</a>.","content":"Paramore is the band's self-titled fourth studio album, released on April 9, 2013 through Fueled by Ramen. It is their first album without co-founders Josh and Zac Farro. When asked about why the album is self-titled, Williams explained \"The self-titled aspect of the whole thing is definitely a statement. I feel like it's not only reintroducing the band to the world, but even to ourselves ... By the end of it, it felt like we're a new band.\" <a href=\"http://www.last.fm/music/Paramore/Paramore\">Read more on Last.fm</a>. User-contributed text is available under the Creative Commons By-SA License; additional terms may apply."}}}
    """#
}
#endif
