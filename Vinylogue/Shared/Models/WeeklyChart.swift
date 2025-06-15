import Foundation

struct WeeklyChart: Codable, Identifiable, Hashable {
    let id = UUID()
    let from: Date
    let to: Date
    let albums: [Album]

    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: from)
    }

    var year: Int {
        Calendar.current.component(.year, from: from)
    }

    init(from: Date, to: Date, albums: [Album] = []) {
        self.from = from
        self.to = to
        self.albums = albums
    }
}
