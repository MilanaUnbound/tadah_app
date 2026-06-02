import Foundation

enum DateHelpers {
    private static let subtitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("EEE, MMM d")
        return f
    }()

    private static let isoKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let chipFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f
    }()

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("EEEE, MMM d, yyyy")
        return f
    }()

    private static let scheduleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return f
    }()

    private static let navigatorMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("MMM")
        return f
    }()

    /// Localized abbreviated month for period navigator (e.g. `Sep`).
    static func navigatorMonthAbbreviation(
        year: Int,
        month: Int,
        calendar: Calendar = .current
    ) -> String {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let date = calendar.date(from: comps) else { return "" }
        return navigatorMonthFormatter.string(from: date)
    }

    static func todaySubtitle(now: Date = Date()) -> String {
        subtitleFormatter.string(from: now)
    }

    static func dateKey(for date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)

        guard
            let year = comps.year,
            let month = comps.month,
            let day = comps.day
        else {
            return "1970-01-01"
        }

        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func todayKey(now: Date = Date()) -> String {
        dateKey(for: now)
    }

    static func startOfToday(now: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: now)
    }

    /// `true` when `key` is before the local calendar day of `now`.
    static func isPastKey(_ key: String, now: Date = Date()) -> Bool {
        key < todayKey(now: now)
    }

    /// `true` when `key` is after the local calendar day of `now`.
    static func isFutureKey(_ key: String, now: Date = Date()) -> Bool {
        key > todayKey(now: now)
    }

    static func scheduleLabel(for date: Date) -> String {
        let key = dateKey(for: date)
        if key == todayKey() {
            return "Today"
        }
        return scheduleFormatter.string(from: date)
    }

    static func keyDaysAgo(fromTodayOffset offset: Int, now: Date = Date()) -> String? {
        guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: now) else {
            return nil
        }
        return dateKey(for: date)
    }

    static func date(fromKey key: String) -> Date? {
        isoKeyFormatter.date(from: key)
    }

    /// Start of the local calendar day for a `dateKey` (used as default `scheduledDate`).
    static func startOfDay(forKey key: String, calendar: Calendar = .current) -> Date? {
        guard let date = date(fromKey: key) else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func chipLabel(forKey key: String) -> String {
        guard let d = date(fromKey: key) else { return key }
        return chipFormatter.string(from: d)
    }

    static func fullDateLabel(forKey key: String) -> String {
        guard let d = date(fromKey: key) else { return key }
        return fullDateFormatter.string(from: d)
    }

    static func offsetKey(_ key: String, byDays delta: Int) -> String? {
        guard let base = date(fromKey: key) else { return nil }
        guard let d = Calendar.current.date(byAdding: .day, value: delta, to: base) else { return nil }
        return dateKey(for: d)
    }

    /// Parses `yyyy-MM-dd` into local calendar year/month (avoids UTC drift from `date(fromKey:)`).
    static func yearMonth(fromKey key: String) -> (year: Int, month: Int)? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              (1 ... 12).contains(month) else {
            return nil
        }
        return (year, month)
    }

    static func dateKey(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// Unique years from task keys plus `now`, sorted newest-first.
    static func availableYears(fromTaskDateKeys keys: [String], now: Date = Date()) -> [Int] {
        var years = Set<Int>()
        years.insert(Calendar.current.component(.year, from: now))

        for key in keys {
            if let ym = yearMonth(fromKey: key) {
                years.insert(ym.year)
            }
        }

        return years.sorted(by: >)
    }
}

