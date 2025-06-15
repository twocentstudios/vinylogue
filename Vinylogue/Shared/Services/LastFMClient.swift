import Foundation

struct LastFMClient {
    private let baseURL = URL(string: "https://ws.audioscrobbler.com/2.0/")!
    private let apiKey = Secrets.apiKey
    private let session = URLSession.shared
    
    init() {}
    
    func request<T: Codable>(_ endpoint: LastFMEndpoint) async throws -> T {
        let url = buildURL(for: endpoint)
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw LastFMError.invalidResponse
        }
        
        // Check for Last.fm API errors
        if let errorResponse = try? JSONDecoder().decode(LastFMErrorResponse.self, from: data) {
            throw LastFMError.apiError(code: errorResponse.error, message: errorResponse.message)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LastFMError.decodingError(error)
        }
    }
    
    func requestData(_ endpoint: LastFMEndpoint) async throws -> Data {
        let url = buildURL(for: endpoint)
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw LastFMError.invalidResponse
        }
        
        return data
    }
    
    private func buildURL(for endpoint: LastFMEndpoint) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json")
        ]
        
        queryItems.append(contentsOf: endpoint.queryItems)
        components.queryItems = queryItems
        
        return components.url!
    }
}

// MARK: - Endpoints

enum LastFMEndpoint {
    case userWeeklyChartList(username: String)
    case userWeeklyAlbumChart(username: String, from: Date, to: Date)
    case albumInfo(artist: String?, album: String?, mbid: String?, username: String?)
    case userInfo(username: String)
    case userFriends(username: String, limit: Int = 500)
    
    var queryItems: [URLQueryItem] {
        switch self {
        case .userWeeklyChartList(let username):
            return [
                URLQueryItem(name: "method", value: "user.getweeklychartlist"),
                URLQueryItem(name: "user", value: username)
            ]
            
        case .userWeeklyAlbumChart(let username, let from, let to):
            return [
                URLQueryItem(name: "method", value: "user.getweeklyalbumchart"),
                URLQueryItem(name: "user", value: username),
                URLQueryItem(name: "from", value: String(Int(from.timeIntervalSince1970))),
                URLQueryItem(name: "to", value: String(Int(to.timeIntervalSince1970)))
            ]
            
        case .albumInfo(let artist, let album, let mbid, let username):
            var items = [URLQueryItem(name: "method", value: "album.getinfo")]
            
            if let mbid = mbid, !mbid.isEmpty {
                items.append(URLQueryItem(name: "mbid", value: mbid))
            } else if let artist = artist, let album = album {
                items.append(URLQueryItem(name: "artist", value: artist))
                items.append(URLQueryItem(name: "album", value: album))
            }
            
            if let username = username {
                items.append(URLQueryItem(name: "username", value: username))
            }
            
            return items
            
        case .userInfo(let username):
            return [
                URLQueryItem(name: "method", value: "user.getinfo"),
                URLQueryItem(name: "user", value: username)
            ]
            
        case .userFriends(let username, let limit):
            return [
                URLQueryItem(name: "method", value: "user.getfriends"),
                URLQueryItem(name: "user", value: username),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        }
    }
}

// MARK: - Error Types

enum LastFMError: Error, LocalizedError {
    case invalidAPIKey
    case userNotFound
    case networkUnavailable
    case invalidResponse
    case serviceUnavailable
    case decodingError(Error)
    case apiError(code: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API configuration"
        case .userNotFound:
            return "User not found. Please check the username."
        case .networkUnavailable:
            return "Network unavailable. Showing cached data."
        case .invalidResponse:
            return "Unable to load data. Please try again."
        case .serviceUnavailable:
            return "Last.fm service is temporarily unavailable"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API Error \(code): \(message)"
        }
    }
}

// MARK: - Response Types

struct LastFMErrorResponse: Codable {
    let error: Int
    let message: String
}