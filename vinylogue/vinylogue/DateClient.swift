import Foundation

struct DateClient {
    var calendar: Calendar
    var date: () -> Date
}

extension DateClient {
    static let live = Self(
        calendar: .autoupdatingCurrent,
        date: { Date() }
    )

    static let mock = Self(
        calendar: .autoupdatingCurrent,
        date: { Date() }
    )
}
