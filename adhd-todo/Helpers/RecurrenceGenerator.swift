import Foundation

enum RecurrenceGeneratorError: Error, Equatable {
    case emptySchedule
    case invalidRule
}

enum RecurrenceGenerator {
    static let defaultHorizonDays = 60

    /// Materializes independent task instances from `anchorDate` through the 60-day window (F-013).
    static func generate(
        title: String,
        category: Category,
        anchorDate: Date,
        rule: RecurrenceRule,
        customWeekdays: Set<Int>,
        seriesId: UUID = UUID(),
        horizonDays: Int = defaultHorizonDays,
        calendar: Calendar = .current
    ) -> Result<[Task], RecurrenceGeneratorError> {
        generate(
            title: title,
            categorySelection: .builtin(category),
            anchorDate: anchorDate,
            rule: rule,
            customWeekdays: customWeekdays,
            seriesId: seriesId,
            horizonDays: horizonDays,
            calendar: calendar
        )
    }

    static func generate(
        title: String,
        categorySelection: CategorySelection,
        anchorDate: Date,
        rule: RecurrenceRule,
        customWeekdays: Set<Int>,
        seriesId: UUID = UUID(),
        horizonDays: Int = defaultHorizonDays,
        calendar: Calendar = .current
    ) -> Result<[Task], RecurrenceGeneratorError> {
        let anchor = calendar.startOfDay(for: anchorDate)
        let placeholderCategory = categorySelection.builtinCategory ?? .other

        guard rule != .none else { return .failure(.invalidRule) }
        guard horizonDays > 0 else { return .failure(.emptySchedule) }
        guard let windowEnd = calendar.date(byAdding: .day, value: horizonDays - 1, to: anchor) else {
            return .failure(.emptySchedule)
        }

        let occurrenceDays: [Date]
        switch rule {
        case .none:
            return .failure(.invalidRule)
        case .daily:
            occurrenceDays = daysInWindow(from: anchor, through: windowEnd, calendar: calendar)
        case .weekly:
            occurrenceDays = weeklyOccurrences(
                anchor: anchor,
                windowEnd: windowEnd,
                calendar: calendar
            )
        case .custom:
            guard customWeekdays.isEmpty == false else { return .failure(.emptySchedule) }
            occurrenceDays = customOccurrences(
                anchor: anchor,
                windowEnd: windowEnd,
                weekdays: customWeekdays,
                calendar: calendar
            )
        }

        guard occurrenceDays.isEmpty == false else { return .failure(.emptySchedule) }

        let mask = rule == .custom ? weekdaysMask(customWeekdays) : nil
        let tasks = occurrenceDays.map { day in
            let key = DateHelpers.dateKey(for: day)
            let task = Task(
                title: title,
                category: placeholderCategory,
                dateKey: key,
                scheduledDate: day,
                recurrenceRule: rule,
                recurrenceSeriesId: seriesId,
                customWeekdaysMask: mask
            )
            categorySelection.apply(to: task)
            return task
        }

        return .success(tasks)
    }

    static func weekdaysMask(_ weekdays: Set<Int>) -> Int {
        weekdays.reduce(0) { partial, weekday in
            partial | (1 << (weekday - 1))
        }
    }

    // MARK: - Private

    private static func daysInWindow(
        from start: Date,
        through end: Date,
        calendar: Calendar
    ) -> [Date] {
        var days: [Date] = []
        var current = start

        while current <= end {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return days
    }

    private static func weeklyOccurrences(
        anchor: Date,
        windowEnd: Date,
        calendar: Calendar
    ) -> [Date] {
        var days: [Date] = []
        var current = anchor

        while current <= windowEnd {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 7, to: current) else { break }
            current = next
        }

        return days
    }

    private static func customOccurrences(
        anchor: Date,
        windowEnd: Date,
        weekdays: Set<Int>,
        calendar: Calendar
    ) -> [Date] {
        var days: [Date] = []
        var current = anchor

        while current <= windowEnd {
            let weekday = calendar.component(.weekday, from: current)
            if weekdays.contains(weekday) {
                days.append(current)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return days
    }
}
