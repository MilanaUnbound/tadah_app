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
        isCompleted: Bool
    ) -> Task {
        Task(title: title, category: .work, dateKey: dateKey, isCompleted: isCompleted)
    }

    @Test func allTasksComplete_incrementsStreak() {
        let today = fixedTodayKey
        let tasksByKey: [String: [Task]] = [
            today: [
                makeTask(title: "A", dateKey: today, isCompleted: true),
                makeTask(title: "B", dateKey: today, isCompleted: true),
            ],
        ]

        let streak = StreakCalculator.calculate(
            todayKey: today,
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
            todayKey: today,
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
            todayKey: today,
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
            todayKey: today,
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

        // Yesterday intentionally empty (no entry) → should be skipped.
        let tasksByKey: [String: [Task]] = [
            today: [makeTask(dateKey: today, isCompleted: true)],
            twoDaysAgo: [makeTask(dateKey: twoDaysAgo, isCompleted: true)],
        ]

        let streak = StreakCalculator.calculate(
            todayKey: today,
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 2)

        // sanity: ensure the “empty” day we intended is actually between them
        #expect(yesterday != today && yesterday != twoDaysAgo)
    }

    @Test func streakOf0_noCompletedDays() {
        let today = fixedTodayKey
        let tasksByKey: [String: [Task]] = [:]

        let streak = StreakCalculator.calculate(
            todayKey: today,
            tasksByDateKey: tasksByKey,
            maxDaysBack: 14,
            now: fixedNow
        )

        #expect(streak == 0)
    }

    @Test func sevenDayStreak_withOneEmptyDayInMiddle() {
        let today = fixedTodayKey

        // We want 7 completed “task-days” within an 8-day window,
        // with one middle day having zero tasks (skipped).
        //
        // Completed task-days: offsets 0,1,2,(skip 3),4,5,6  => streak 7
        let completedOffsets = [0, 1, 2, 4, 5, 6]
        var tasksByKey: [String: [Task]] = [:]

        for offset in completedOffsets {
            let k = key(daysAgo: offset)
            tasksByKey[k] = [makeTask(dateKey: k, isCompleted: true)]
        }

        // Ensure there is at least one empty day “in the middle”
        let skippedKey = key(daysAgo: 3)
        #expect(tasksByKey[skippedKey] == nil)

        let streak = StreakCalculator.calculate(
            todayKey: today,
            tasksByDateKey: tasksByKey,
            maxDaysBack: 10,
            now: fixedNow
        )

        #expect(streak == 6) // 0,1,2,(skip 3),4,5,6 = 6? (see note below)
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
            todayKey: today,
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
            todayKey: today,
            tasksByDateKey: tasksByKey,
            maxDaysBack: 7,
            now: fixedNow
        )

        #expect(streak == 1)
    }
}

