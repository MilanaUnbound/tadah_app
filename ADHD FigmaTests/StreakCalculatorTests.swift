import Foundation
import Testing

@testable import ADHD_Figma

struct StreakCalculatorTests {
    private let fixedNow = Date(timeIntervalSince1970: 1_700_000_000) // deterministic

    private var fixedTodayKey: String {
        DateHelpers.todayKey(now: fixedNow)
    }

    private func key(daysAgo: Int) -> String {
        DateHelpers.keyDaysAgo(fromTodayOffset: daysAgo, now: fixedNow)!
    }

    private func makeTask(
        title: String = "T",
        dateKey: String,
        isCompleted: Bool,
        isBonus: Bool = false
    ) -> Task {
        Task(
            title: title,
            category: .work,
            dateKey: dateKey,
            isCompleted: isCompleted,
            isBonus: isBonus
        )
    }

    private func makeRecurringTask(
        dateKey: String,
        isCompleted: Bool,
        seriesId: UUID = UUID()
    ) -> Task {
        Task(
            title: "Daily",
            category: .work,
            dateKey: dateKey,
            isCompleted: isCompleted,
            recurrenceRule: .daily,
            recurrenceSeriesId: seriesId
        )
    }

    @Test func allNormalTasksComplete_incrementsStreak() {
        let today = fixedTodayKey
        let tasksByKey: [String: [Task]] = [
            today: [
                makeTask(title: "A", dateKey: today, isCompleted: true),
                makeTask(title: "B", dateKey: today, isCompleted: true),
            ],
        ]

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 1)
    }

    @Test func incompleteToday_doesNotBreakPastStreak() {
        let today = fixedTodayKey
        let yesterday = key(daysAgo: 1)
        let tasksByKey: [String: [Task]] = [
            yesterday: [makeTask(dateKey: yesterday, isCompleted: true)],
            today: [
                makeTask(title: "A", dateKey: today, isCompleted: true),
                makeTask(title: "B", dateKey: today, isCompleted: false),
            ],
        ]

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 1)
    }

    @Test func incompleteYesterday_breaksStreak_whenTodayEmpty() {
        let today = fixedTodayKey
        let yesterday = key(daysAgo: 1)
        let tasksByKey: [String: [Task]] = [
            yesterday: [
                makeTask(dateKey: yesterday, isCompleted: true),
                makeTask(dateKey: yesterday, isCompleted: false),
            ],
        ]

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 0)
    }

    @Test func incompleteYesterday_breaksStreak_onlyCountsTodayIfComplete() {
        let today = fixedTodayKey
        let yesterday = key(daysAgo: 1)
        let tasksByKey: [String: [Task]] = [
            yesterday: [makeTask(dateKey: yesterday, isCompleted: false)],
            today: [makeTask(dateKey: today, isCompleted: true)],
        ]

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 1)
    }

    @Test func emptyDaySkipped_doesNotBreakStreak() {
        let today = fixedTodayKey
        let yesterday = key(daysAgo: 1)
        let twoDaysAgo = key(daysAgo: 2)

        let tasksByKey: [String: [Task]] = [
            today: [makeTask(dateKey: today, isCompleted: true)],
            twoDaysAgo: [makeTask(dateKey: twoDaysAgo, isCompleted: true)],
        ]

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 2)
        #expect(yesterday != today && yesterday != twoDaysAgo)
    }

    @Test func streakOf0_noCompletedDays() {
        let tasksByKey: [String: [Task]] = [:]

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 14,
            now: fixedNow
        )

        #expect(streak == 0)
    }

    @Test func sixDayStreak_withOneEmptyDayInMiddle() {
        let completedOffsets = [0, 1, 2, 4, 5, 6]
        var tasksByKey: [String: [Task]] = [:]

        for offset in completedOffsets {
            let dayKey = key(daysAgo: offset)
            tasksByKey[dayKey] = [makeTask(dateKey: dayKey, isCompleted: true)]
        }

        let skippedKey = key(daysAgo: 3)
        #expect(tasksByKey[skippedKey] == nil)

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 10,
            now: fixedNow
        )

        #expect(streak == 6)
    }

    @Test func sevenConsecutiveDays_streakIs7() {
        var tasksByKey: [String: [Task]] = [:]

        for offset in 0..<7 {
            let dayKey = key(daysAgo: offset)
            tasksByKey[dayKey] = [
                makeTask(title: "A", dateKey: dayKey, isCompleted: true),
                makeTask(title: "B", dateKey: dayKey, isCompleted: true),
                makeTask(title: "C", dateKey: dayKey, isCompleted: true),
            ]
        }

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 14,
            now: fixedNow
        )

        #expect(streak == 7)
    }

    @Test func weekdaySuccess_weekendIncompleteRecurring_streakIs1OnMonday() {
        let seriesId = UUID()
        var tasksByKey: [String: [Task]] = [:]

        for offset in 0..<5 {
            let dayKey = key(daysAgo: offset)
            tasksByKey[dayKey] = [
                makeTask(title: "A", dateKey: dayKey, isCompleted: true),
                makeTask(title: "B", dateKey: dayKey, isCompleted: true),
                makeTask(title: "C", dateKey: dayKey, isCompleted: true),
            ]
        }

        for offset in 5..<7 {
            let dayKey = key(daysAgo: offset)
            tasksByKey[dayKey] = [
                makeRecurringTask(dateKey: dayKey, isCompleted: false, seriesId: seriesId),
            ]
        }

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 14,
            now: fixedNow
        )

        #expect(streak == 1)
    }

    @Test func todayAllNormalComplete_withBonusIncomplete_countsToday() {
        let today = fixedTodayKey
        let tasksByKey: [String: [Task]] = [
            today: [
                makeTask(title: "A", dateKey: today, isCompleted: true),
                makeTask(title: "B", dateKey: today, isCompleted: true),
                makeTask(title: "C", dateKey: today, isCompleted: true),
                makeTask(title: "Bonus", dateKey: today, isCompleted: false, isBonus: true),
            ],
        ]

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 1)
    }

    @Test func partialCompletion_doesNotCountDay() {
        let today = fixedTodayKey
        let tasksByKey: [String: [Task]] = [
            today: [
                makeTask(title: "A", dateKey: today, isCompleted: true),
                makeTask(title: "B", dateKey: today, isCompleted: true),
                makeTask(title: "C", dateKey: today, isCompleted: false),
            ],
        ]

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 0)
    }

    @Test func futureDateKey_doesNotIncreaseStreak() {
        let today = fixedTodayKey
        guard let tomorrow = DateHelpers.offsetKey(today, byDays: 1) else {
            Issue.record("Missing tomorrow key")
            return
        }

        let tasksByKey: [String: [Task]] = [
            tomorrow: [makeTask(dateKey: tomorrow, isCompleted: false)],
        ]

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 0)
    }

    @Test func futureIncomplete_doesNotBreakStreak() {
        let today = fixedTodayKey
        guard let tomorrow = DateHelpers.offsetKey(today, byDays: 1) else {
            Issue.record("Missing tomorrow key")
            return
        }

        let tasksByKey: [String: [Task]] = [
            today: [makeTask(dateKey: today, isCompleted: true)],
            tomorrow: [makeTask(dateKey: tomorrow, isCompleted: false)],
        ]

        let streak = StreakCalculator.calculate(
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 1)
    }

    @Test func tasksByDateKey_excludesFutureDates() {
        let today = fixedTodayKey
        guard let tomorrow = DateHelpers.offsetKey(today, byDays: 1) else {
            Issue.record("Missing tomorrow key")
            return
        }

        let allTasks = [
            makeTask(dateKey: today, isCompleted: true),
            makeTask(dateKey: tomorrow, isCompleted: false),
        ]

        let byDate = StreakCalculator.tasksByDateKey(from: allTasks, now: fixedNow)

        #expect(byDate[today]?.count == 1)
        #expect(byDate[tomorrow] == nil)
    }
}

struct DayCompletionHelperTests {
    @Test func allNormalTasksComplete_ignoresBonusTasks() {
        let today = DateHelpers.todayKey()
        let tasks = [
            Task(title: "A", category: .work, dateKey: today, isCompleted: true),
            Task(title: "B", category: .work, dateKey: today, isCompleted: true),
            Task(title: "Bonus", category: .work, dateKey: today, isCompleted: false, isBonus: true),
        ]

        #expect(DayCompletionHelper.allNormalTasksComplete(tasks: tasks))
    }

    @Test func allNormalTasksComplete_falseWhenAnyNormalIncomplete() {
        let today = DateHelpers.todayKey()
        let tasks = [
            Task(title: "A", category: .work, dateKey: today, isCompleted: true),
            Task(title: "B", category: .work, dateKey: today, isCompleted: false),
        ]

        #expect(DayCompletionHelper.allNormalTasksComplete(tasks: tasks) == false)
    }
}
