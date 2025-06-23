import Foundation

struct WeeklyChart: Codable, Hashable, Sendable {
    let from: Date
    let to: Date
    let albums: [UserChartAlbum]

    init(from: Date, to: Date, albums: [UserChartAlbum] = []) {
        self.from = from
        self.to = to
        self.albums = albums
    }
}
