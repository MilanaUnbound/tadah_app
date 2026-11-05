import Foundation

enum StreakCalculator {
    static func calculate(
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

            let normalTasks = DayCompletionHelper.normalTasks(from: tasks)
            if normalTasks.isEmpty {
                continue
            }

            if DayCompletionHelper.allNormalTasksComplete(tasks: tasks) {
                streak += 1
                continue
            }

            // In-progress today: do not break the streak until the calendar day ends.
            if offset == 0 {
                continue
            }

            break
        }

        return streak
    }

    static func tasksByDateKey(from allTasks: [Task], now: Date = Date()) -> [String: [Task]] {
        let todayKey = DateHelpers.todayKey(now: now)
        var byDate: [String: [Task]] = [:]
        byDate.reserveCapacity(64)

        for task in allTasks {
            guard task.isDump == false else { continue }
            guard task.dateKey <= todayKey else { continue }
            byDate[task.dateKey, default: []].append(task)
        }

        return byDate
    }
}
