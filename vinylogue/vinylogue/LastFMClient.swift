import ComposableArchitecture
import Foundation

struct LastFMClient {
    let verifyUsername: (String) -> Effect<Username, LoginError>
    let friendsForUsername: (Username) -> Effect<[Username], FavoriteUsersError>
}

// Namespace
enum LastFM {}

extension LastFM {
    struct Request: Equatable {
        let baseURL: URL
        let apiKey: String
        let format = "json"
        let method = "GET"

        var urlRequest: URLRequest {
            var request = URLRequest(url: baseURL)
            request.setValue(apiKey, forHTTPHeaderField: "api_key")
            request.setValue(format, forHTTPHeaderField: "format")
            request.httpMethod = method
            return request
        }
    }

    struct GetUserRequest {
        let method = "user.getinfo"
        let username: Username
        let responseType: GetUserResponse.Type

        func appendParameters(to urlRequest: inout URLRequest) {
            urlRequest.setValue(method, forHTTPHeaderField: "method")
            urlRequest.setValue(username, forHTTPHeaderField: "user")
        }
    }

    struct GetFriendsRequest {
        let method = "user.getfriends"
        let username: Username
        let limit = "500"
        let responseType: GetFriendsResponse.Type

        func appendParameters(to urlRequest: inout URLRequest) {
            urlRequest.setValue(method, forHTTPHeaderField: "method")
            urlRequest.setValue(username, forHTTPHeaderField: "user")
            urlRequest.setValue(limit, forHTTPHeaderField: "limit")
        }
    }

    struct GetWeeklyChartListRequest {
        let method = "user.getweeklychartlist"
        let username: Username
        let responseType: GetWeeklyChartListResponse.Type

        func appendParameters(to urlRequest: inout URLRequest) {
            urlRequest.setValue(method, forHTTPHeaderField: "method")
            urlRequest.setValue(username, forHTTPHeaderField: "user")
        }
    }

    struct GetWeeklyAlbumChartRequest {
        let method = "user.getweeklyalbumchart"
        let username: Username
        let range: WeeklyChartRange
        let responseType: GetWeeklyAlbumChartResponse.Type

        func appendParameters(to urlRequest: inout URLRequest) {
            urlRequest.setValue(method, forHTTPHeaderField: "method")
            urlRequest.setValue(username, forHTTPHeaderField: "user")
            urlRequest.setValue(String(range.from.timeIntervalSince1970), forHTTPHeaderField: "from")
            urlRequest.setValue(String(range.to.timeIntervalSince1970), forHTTPHeaderField: "to")
        }
    }

    struct GetAlbumRequest {
        let method = "album.getinfo"
        let username: Username
        let artist: ArtistStub
        let album: AlbumStub
        let responseType: GetWeeklyAlbumChartResponse.Type

        func appendParameters(to urlRequest: inout URLRequest) {
            urlRequest.setValue(method, forHTTPHeaderField: "method")
            urlRequest.setValue(username, forHTTPHeaderField: "username")
            if let mbid = album.mbid {
                urlRequest.setValue(mbid, forHTTPHeaderField: "mbid")
            } else {
                urlRequest.setValue(artist.name, forHTTPHeaderField: "artist")
                urlRequest.setValue(album.name, forHTTPHeaderField: "album")
            }
        }
    }
}

extension LastFM {
    struct GetUserResponse: Equatable, Decodable {
        let user: User
    }

    struct GetFriendsResponse: Equatable, Decodable {
        let friends: [FriendUser]

        enum CodingKeys: String, CodingKey {
            case friends
        }

        enum FriendsKeys: String, CodingKey {
            case user // array
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let friendsContainer = try values.nestedContainer(keyedBy: FriendsKeys.self, forKey: .friends)
            friends = try friendsContainer.decode([FriendUser].self, forKey: .user)
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
        let album: [Album]
    }
}

extension LastFM {
    struct User: Equatable, Decodable {
        let username: String

        enum CodingKeys: String, CodingKey {
            case username = "user"
        }
    }

    struct FriendUser: Equatable, Decodable {
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

    struct WeeklyChartRange: Equatable, Decodable {
        let from: Date // unix timestamp
        let to: Date
    }

    struct WeeklyAlbumCharts: Equatable, Decodable {
        let charts: [WeeklyAlbumChartStub]

        enum CodingKeys: String, CodingKey {
            case charts = "album"
        }
    }

    struct WeeklyAlbumChartStub: Equatable, Decodable {
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

    struct ArtistStub: Equatable, Decodable {
        let mbid: String?
        let name: String

        enum CodingKeys: String, CodingKey {
            case mbid
            case name = "#text"
        }
    }

    struct AlbumStub: Equatable {
        let mbid: String?
        let name: String
    }

    struct Album: Equatable, Decodable {
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

            let wikiValues = try values.nestedContainer(keyedBy: WikiKeys.self, forKey: .wiki)
            about = try wikiValues.decodeIfPresent(String.self, forKey: .content)

            let tracksValues = try values.nestedContainer(keyedBy: TracksKeys.self, forKey: .tracks)
            tracks = try tracksValues.decodeIfPresent([Track].self, forKey: .track)

            let imageValues = try values.decodeIfPresent([Image].self, forKey: .image)
            imageSet = imageValues.map { ImageSet(images: $0) }
        }
    }

    struct Track: Equatable, Decodable {
        let name: String
        let seconds: Int?

        enum CodingKeys: String, CodingKey {
            case name
            case seconds = "duration"
        }
    }

    struct ImageSet: Equatable, Decodable {
        let images: [Image]
    }

    struct Image: Equatable, Decodable {
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
