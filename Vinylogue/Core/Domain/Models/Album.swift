import Foundation
import SwiftUI
import UIKit

// MARK: - Album Detail Information

struct AlbumDetail: Codable, Hashable, Sendable {
    let name: String
    let artist: String
    let url: String?
    let mbid: String?
    let imageURL: String?
    let description: String?
    let totalPlayCount: Int?
    let userPlayCount: Int?

    init(name: String, artist: String, url: String?, mbid: String?, imageURL: String?, description: String?, totalPlayCount: Int?, userPlayCount: Int?) {
        self.name = name
        self.artist = artist
        self.url = url
        self.mbid = mbid
        self.imageURL = imageURL
        self.description = description
        self.totalPlayCount = totalPlayCount
        self.userPlayCount = userPlayCount
    }
}

struct UserChartAlbum: Codable, Identifiable, Hashable, Sendable {
    // Chart context (identifies the specific chart this data comes from)
    let username: String
    let weekNumber: Int
    let year: Int

    // Album identification
    let name: String
    let artist: String
    let url: String?
    let mbid: String?

    // Chart-specific data
    let playCount: Int // User's plays for this specific week
    let rank: Int?

    // Optional detail data (from AlbumInfo API)
    var detail: Detail?

    // Identifiable conformance - includes user and time context
    var id: String { "\(username):\(year):\(weekNumber):\(artist):\(name)" }

    struct Detail: Codable, Hashable, Sendable {
        let imageURL: String?
        let description: String?
        let totalPlayCount: Int? // Total scrobbles across all users
        let userPlayCount: Int? // User's all-time plays

        // Color extraction cache (not encoded/decoded)
        private var _dominantColor: Color?
        private var _colorExtractionAttempted: Bool = false

        enum CodingKeys: String, CodingKey {
            case imageURL, description, totalPlayCount, userPlayCount
            // Exclude color cache from encoding/decoding
        }

        init(imageURL: String?, description: String?, totalPlayCount: Int?, userPlayCount: Int?) {
            self.imageURL = imageURL
            self.description = description
            self.totalPlayCount = totalPlayCount
            self.userPlayCount = userPlayCount
        }

        // MARK: - Color Extraction Methods

        /// Lazily extracts and caches the dominant color from the album artwork
        /// - Parameter image: The album artwork image to extract color from
        /// - Returns: The dominant color if extraction succeeds, otherwise nil
        mutating func dominantColor(from image: UIImage?) -> Color? {
            // Return cached color if available
            if _colorExtractionAttempted {
                return _dominantColor
            }

            // Mark as attempted to avoid repeated processing
            _colorExtractionAttempted = true

            // Extract color from provided image
            guard let image else { return nil }

            _dominantColor = ColorExtraction.dominantColor(from: image)
            return _dominantColor
        }

        /// Returns the cached dominant color without triggering extraction
        var cachedDominantColor: Color? {
            _dominantColor
        }

        /// Clears the cached color (useful when image changes)
        mutating func clearColorCache() {
            _dominantColor = nil
            _colorExtractionAttempted = false
        }
    }

    init(username: String, weekNumber: Int, year: Int, name: String, artist: String, playCount: Int, rank: Int? = nil, url: String? = nil, mbid: String? = nil) {
        self.username = username
        self.weekNumber = weekNumber
        self.year = year
        self.name = name
        self.artist = artist
        self.playCount = playCount
        self.rank = rank
        self.url = url
        self.mbid = mbid
    }
}

// MARK: - Convenience Properties

extension UserChartAlbum {
    /// Whether detail information has been loaded
    var isDetailLoaded: Bool {
        detail != nil
    }

    /// Convenience accessor for image URL
    var imageURL: String? {
        detail?.imageURL
    }

    /// Convenience accessor for description
    var description: String? {
        detail?.description
    }

    /// Convenience accessor for total play count
    var totalPlayCount: Int? {
        detail?.totalPlayCount
    }

    /// Convenience accessor for user play count
    var userPlayCount: Int? {
        detail?.userPlayCount
    }
}

// MARK: - Color Extraction Extension

extension UserChartAlbum {
    /// Lazily extracts and caches the dominant color from the album artwork
    /// - Parameter image: The album artwork image to extract color from
    /// - Returns: The dominant color if extraction succeeds, otherwise nil
    mutating func dominantColor(from image: UIImage?) -> Color? {
        guard detail != nil else { return nil }
        return detail!.dominantColor(from: image)
    }

    /// Returns the cached dominant color without triggering extraction
    var cachedDominantColor: Color? {
        detail?.cachedDominantColor
    }

    /// Clears the cached color (useful when image changes)
    mutating func clearColorCache() {
        detail?.clearColorCache()
    }
}
