import Foundation

struct WeeklyChart: Codable, Hashable, Sendable {
    let from: Date
    let to: Date
    let albums: [UserChartAlbum]

    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: from)
    }

    var year: Int {
        Calendar.current.component(.year, from: from)
    }

    init(from: Date, to: Date, albums: [UserChartAlbum] = []) {
        self.from = from
        self.to = to
        self.albums = albums
    }
}
