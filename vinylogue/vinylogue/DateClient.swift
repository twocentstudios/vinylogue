import Foundation

struct DateClient {
    var calendar: Calendar
    var date: () -> Date
    var yearFormatter: (Date) -> String
}

extension DateClient {
    static let yearDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY"
        return formatter
    }()

    static let live = Self(
        calendar: .autoupdatingCurrent,
        date: { Date() },
        yearFormatter: yearDateFormatter.string(from:)
    )

    static let mock = Self(
        calendar: .autoupdatingCurrent,
        date: { Date() },
        yearFormatter: { _ in "2019" }
    )
}
