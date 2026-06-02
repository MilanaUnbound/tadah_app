import Foundation

enum HistoryDateNavigation {
    /// Most recent `dateKey` in the given month that has tasks, or the 1st of that month (F-014 / B-021).
    static func landingDateKey(
        year: Int,
        month: Int,
        taskDateKeys: [String],
        calendar: Calendar = .current
    ) -> String {
        let prefix = String(format: "%04d-%02d", year, month)
        let matching = taskDateKeys.filter { $0.hasPrefix(prefix) }

        if let latest = matching.max() {
            return latest
        }

        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1

        if let date = calendar.date(from: comps) {
            return DateHelpers.dateKey(for: date)
        }

        return DateHelpers.dateKey(year: year, month: month, day: 1)
    }
}
