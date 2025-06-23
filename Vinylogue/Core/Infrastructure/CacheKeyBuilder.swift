import Foundation

enum CacheKeyBuilder {
    // MARK: - Chart-related cache keys

    /// Creates a cache key for weekly chart data
    static func weeklyChart(username: String, from: Date, to: Date) -> String {
        "weekly_chart_\(username)_\(timestamp(from: from))_\(timestamp(from: to))"
    }

    /// Creates a cache key for weekly chart list data
    static func weeklyChartList(username: String) -> String {
        "weekly_chart_list_\(username)"
    }

    /// Creates a cache key for chart data (generic chart format)
    static func chart(user: String, from: Date, to: Date) -> String {
        "chart_\(user)_\(timestamp(from: from))_\(timestamp(from: to))"
    }

    // MARK: - Album-related cache keys

    /// Creates a cache key for album info based on MBID
    static func albumInfo(mbid: String, username: String? = nil) -> String {
        "album_info_mbid_\(mbid)_\(username ?? "none")"
    }

    /// Creates a cache key for album info based on artist and album name
    static func albumInfo(artist: String, album: String, username: String? = nil) -> String {
        "album_info_\(normalize(artist))_\(normalize(album))_\(username ?? "none")"
    }

    /// Creates a cache key for album info based on available identifiers
    static func albumInfo(
        artist: String? = nil,
        album: String? = nil,
        mbid: String? = nil,
        username: String? = nil
    ) -> String? {
        // Prioritize MBID as it's more reliable
        if let mbid, !mbid.isEmpty {
            albumInfo(mbid: mbid, username: username)
        } else if let artist, let album {
            albumInfo(artist: artist, album: album, username: username)
        } else {
            nil // Insufficient data to create cache key
        }
    }

    // MARK: - User-related cache keys

    /// Creates a cache key for user data
    static func user(_ username: String) -> String {
        "user_\(username)"
    }

    /// Creates a cache key for user friends data
    static func userFriends(_ username: String) -> String {
        "user_friends_\(username)"
    }

    // MARK: - Generic cache key utilities

    /// Creates a timestamp-based cache key component
    static func timestamp(from date: Date) -> String {
        String(Int(date.timeIntervalSince1970))
    }

    /// Normalizes a string for use in cache keys (lowercase, spaces to underscores)
    static func normalize(_ string: String) -> String {
        string.lowercased().replacingOccurrences(of: " ", with: "_")
    }
}
