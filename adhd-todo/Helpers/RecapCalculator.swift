import Foundation

enum RecapCalculator {
    enum Period: Equatable {
        case month(year: Int, month: Int)
        case year(Int)
    }

    struct Summary: Equatable {
        let totalAdded: Int
        let totalCompleted: Int
        let completionRate: Int // percent 0...100
        let byCategory: [CategoryBreakdown]
    }

    struct CategoryBreakdown: Equatable, Identifiable {
        var id: String { groupKey }
        let groupKey: String
        let displayName: String
        let colorHex: String
        let completedCount: Int
        let completedPercent: Int // percent 0...100 of completed tasks
    }

    static func calculate(
        allTasks: [Task],
        period: Period,
        projects: [Project] = [],
        now: Date = Date()
    ) -> Summary {
        let todayKey = DateHelpers.todayKey(now: now)
        let excludeToday = shouldExcludeTodayFromRecap(allTasks: allTasks, todayKey: todayKey)

        let filtered = allTasks.filter { task in
            if excludeToday, task.dateKey == todayKey { return false }
            guard DateHelpers.isFutureKey(task.dateKey, now: now) == false else { return false }
            return isTask(task, in: period)
        }

        let totalAdded = filtered.count
        let completed = filtered.filter(\.isCompleted)
        let totalCompleted = completed.count

        let completionRate: Int = {
            guard totalAdded > 0 else { return 0 }
            return Int(round((Double(totalCompleted) / Double(totalAdded)) * 100))
        }()

        let byCategory: [CategoryBreakdown] = {
            let completedByKey = Dictionary(grouping: completed, by: \.categoryRaw)
            let denom = max(1, totalCompleted)

            return completedByKey.map { groupKey, tasks in
                let count = tasks.count
                let pct = totalCompleted == 0 ? 0 : Int(round((Double(count) / Double(denom)) * 100))
                let sample = tasks[0]
                let info = TaskCategoryDisplay.breakdownInfo(
                    forGroupKey: groupKey,
                    sampleTask: sample,
                    projects: projects
                )
                return CategoryBreakdown(
                    groupKey: groupKey,
                    displayName: info.displayName,
                    colorHex: info.colorHex,
                    completedCount: count,
                    completedPercent: pct
                )
            }
            .sorted { lhs, rhs in
                if lhs.completedCount != rhs.completedCount { return lhs.completedCount > rhs.completedCount }
                return lhs.displayName < rhs.displayName
            }
        }()

        return Summary(
            totalAdded: totalAdded,
            totalCompleted: totalCompleted,
            completionRate: completionRate,
            byCategory: byCategory
        )
    }

    /// Excludes today when there is at least one task and any is incomplete.
    private static func shouldExcludeTodayFromRecap(allTasks: [Task], todayKey: String) -> Bool {
        let todayTasks = allTasks.filter { $0.dateKey == todayKey }
        guard !todayTasks.isEmpty else { return false }
        return !todayTasks.allSatisfy(\.isCompleted)
    }

    private static func isTask(_ task: Task, in period: Period) -> Bool {
        guard let date = DateHelpers.date(fromKey: task.dateKey) else { return false }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0

        switch period {
        case .month(let year, let month):
            return y == year && m == month
        case .year(let year):
            return y == year
        }
    }
}
