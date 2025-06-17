import Foundation
import SwiftUI
import UIKit

struct Album: Codable, Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let artist: String
    var imageURL: String?
    let playCount: Int
    let rank: Int?
    let url: String?
    let mbid: String?

    // Detail view properties (loaded separately)
    var description: String?
    var totalPlayCount: Int?
    var userPlayCount: Int?
    var isDetailLoaded: Bool = false

    // Color extraction cache (not encoded/decoded)
    private var _dominantColor: Color?
    private var _colorExtractionAttempted: Bool = false

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case name, artist, imageURL, playCount, rank, url, mbid
        case description, totalPlayCount, userPlayCount, isDetailLoaded
        // Exclude _dominantColor and _colorExtractionAttempted from encoding/decoding
    }

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

// MARK: - Color Extraction Extension

extension Album {
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
