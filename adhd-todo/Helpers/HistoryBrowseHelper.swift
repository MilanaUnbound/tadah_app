import Foundation
import SwiftUI

enum HistoryPeriod: String, CaseIterable, Identifiable {
    case month
    case year
    case project

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }
}

struct HistoryProjectSummary: Identifiable {
    let categoryRaw: String
    let displayName: String
    let color: Color
    let doneCount: Int
    let totalCount: Int

    var id: String { categoryRaw }

    var percent: Int {
        guard totalCount > 0 else { return 0 }
        return Int(round((Double(doneCount) / Double(totalCount)) * 100))
    }
}

enum HistoryBrowseHelper {
    static func resolvedCompletedAt(for task: Task, calendar: Calendar = .current) -> Date? {
        guard task.isCompleted else { return nil }
        if let completedAt = task.completedAt { return completedAt }
        return DateHelpers.startOfDay(forKey: task.dateKey, calendar: calendar)
    }

    static func completedTasks(
        from tasks: [Task],
        period: HistoryPeriod,
        viewYear: Int,
        viewMonth: Int,
        calendar: Calendar = .current
    ) -> [Task] {
        guard period != .project else { return [] }

        return tasks.filter { task in
            guard let completedAt = resolvedCompletedAt(for: task, calendar: calendar) else {
                return false
            }
            let comps = calendar.dateComponents([.year, .month], from: completedAt)
            let year = comps.year ?? 0
            let month = comps.month ?? 0

            switch period {
            case .month:
                return year == viewYear && month == viewMonth
            case .year:
                return year == viewYear
            case .project:
                return false
            }
        }
    }

    static func groupedCompletedTasks(
        from tasks: [Task],
        period: HistoryPeriod,
        viewYear: Int,
        viewMonth: Int,
        calendar: Calendar = .current
    ) -> [(label: String, tasks: [Task])] {
        let filtered = completedTasks(
            from: tasks,
            period: period,
            viewYear: viewYear,
            viewMonth: viewMonth,
            calendar: calendar
        )

        let grouped = Dictionary(grouping: filtered) { task in
            groupLabel(for: task, period: period, calendar: calendar)
        }

        return grouped
            .map { label, tasks in
                let sorted = tasks.sorted { lhs, rhs in
                    let lDate = resolvedCompletedAt(for: lhs, calendar: calendar) ?? .distantPast
                    let rDate = resolvedCompletedAt(for: rhs, calendar: calendar) ?? .distantPast
                    if lDate != rDate { return lDate > rDate }
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return (label: label, tasks: sorted)
            }
            .sorted { lhs, rhs in
                let lDate = resolvedCompletedAt(for: lhs.tasks[0], calendar: calendar) ?? .distantPast
                let rDate = resolvedCompletedAt(for: rhs.tasks[0], calendar: calendar) ?? .distantPast
                return lDate > rDate
            }
    }

    static func uniqueCategoryKeys(from tasks: [Task]) -> [String] {
        Array(Set(tasks.map(\.categoryRaw))).sorted()
    }

    static func tasks(forCategoryRaw key: String, from tasks: [Task]) -> [Task] {
        tasks
            .filter { $0.categoryRaw == key }
            .sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted { return lhs.isCompleted == false }
                if lhs.dateKey != rhs.dateKey { return lhs.dateKey > rhs.dateKey }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    static func projectSummaries(
        from tasks: [Task],
        projects: [Project],
        search: String
    ) -> [HistoryProjectSummary] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let keys = uniqueCategoryKeys(from: tasks)

        return keys.compactMap { key in
            let matching = tasks.filter { $0.categoryRaw == key }
            guard let sample = matching.first else { return nil }

            let name = TaskCategoryDisplay.displayName(for: sample, projects: projects)
            if query.isEmpty == false, name.lowercased().contains(query) == false {
                return nil
            }

            let done = matching.filter(\.isCompleted).count
            return HistoryProjectSummary(
                categoryRaw: key,
                displayName: name,
                color: TaskCategoryDisplay.displayColor(for: sample, projects: projects),
                doneCount: done,
                totalCount: matching.count
            )
        }
        .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    static func periodLabel(
        period: HistoryPeriod,
        viewYear: Int,
        viewMonth: Int,
        calendar: Calendar = .current
    ) -> String {
        switch period {
        case .year:
            return String(viewYear)
        case .month, .project:
            var comps = DateComponents()
            comps.year = viewYear
            comps.month = viewMonth
            comps.day = 1
            guard let date = calendar.date(from: comps) else { return "" }
            let formatter = DateFormatter()
            formatter.locale = .current
            formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            return formatter.string(from: date)
        }
    }

    static func stepMonth(viewYear: inout Int, viewMonth: inout Int, direction: Int) {
        var month = viewMonth + direction
        var year = viewYear
        if month > 12 {
            month = 1
            year += 1
        } else if month < 1 {
            month = 12
            year -= 1
        }
        viewMonth = month
        viewYear = year
    }

    static func stepYear(viewYear: inout Int, direction: Int) {
        viewYear += direction
    }

    // MARK: - Private

    private static func groupLabel(
        for task: Task,
        period: HistoryPeriod,
        calendar: Calendar
    ) -> String {
        guard let date = resolvedCompletedAt(for: task, calendar: calendar) else { return "" }

        switch period {
        case .year:
            let formatter = DateFormatter()
            formatter.locale = .current
            formatter.setLocalizedDateFormatFromTemplate("MMMM")
            return formatter.string(from: date)
        case .month, .project:
            let formatter = DateFormatter()
            formatter.locale = .current
            formatter.setLocalizedDateFormatFromTemplate("EEE, MMM d")
            return formatter.string(from: date)
        }
    }
}
