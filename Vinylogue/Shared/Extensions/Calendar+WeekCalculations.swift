import Foundation

extension Calendar {
    /// Calculate the same week from N years ago
    func sameWeekInPreviousYear(_ date: Date, yearsAgo: Int) -> Date? {
        var components = DateComponents()
        components.year = -yearsAgo
        return self.date(byAdding: components, to: date)
    }

    /// Get the week number and year for week-of-year calculations
    func weekComponents(from date: Date) -> (weekOfYear: Int, yearForWeekOfYear: Int) {
        let components = dateComponents([.weekOfYear, .yearForWeekOfYear], from: date)
        return (
            weekOfYear: components.weekOfYear ?? 1,
            yearForWeekOfYear: components.yearForWeekOfYear ?? component(.year, from: date)
        )
    }

    /// Check if two dates are in the same week
    func isDate(_ date1: Date, inSameWeekAs date2: Date) -> Bool {
        let week1 = weekComponents(from: date1)
        let week2 = weekComponents(from: date2)
        return week1.weekOfYear == week2.weekOfYear && week1.yearForWeekOfYear == week2.yearForWeekOfYear
    }
}

extension Date {
    /// Get a date representing the same week N years ago
    func shiftedByYears(_ years: Int, calendar: Calendar = .current) -> Date {
        calendar.sameWeekInPreviousYear(self, yearsAgo: years) ?? self
    }

    /// Get week number and year components
    var weekComponents: (weekOfYear: Int, yearForWeekOfYear: Int) {
        Calendar.current.weekComponents(from: self)
    }
}
