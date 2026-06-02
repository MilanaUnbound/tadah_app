import Foundation

enum StreakCalculator {
    static func calculate(
        todayKey: String,
        tasksByDateKey: [String: [Task]],
        maxDaysBack: Int = 90,
        now: Date = Date()
    ) -> Int {
        var streak = 0

        for offset in 0..<maxDaysBack {
            guard let key = DateHelpers.keyDaysAgo(fromTodayOffset: offset, now: now) else {
                break
            }

            let tasks = tasksByDateKey[key] ?? []
            if tasks.isEmpty {
                continue
            }

            let normalTasks = tasks.filter { $0.isBonus == false }
            if normalTasks.isEmpty {
                continue
            }

            if normalTasks.allSatisfy(\.isCompleted) {
                streak += 1
                continue
            }

            // In-progress today: do not break the streak until the calendar day ends.
            // A failed day only counts after rollover (offset > 0).
            if offset == 0 {
                continue
            }

            break
        }

        return streak
    }
}
