import Foundation
import Testing
@testable import ADHD_Figma

struct RecapCalculatorTests {
    private let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)

    private var todayKey: String {
        DateHelpers.todayKey(now: fixedNow)
    }

    private func key(daysAgo: Int) -> String? {
        DateHelpers.keyDaysAgo(fromTodayOffset: daysAgo, now: fixedNow)
    }

    private func key(daysFromToday offset: Int) -> String? {
        DateHelpers.offsetKey(todayKey, byDays: offset)
    }

    private func makeTask(dateKey: String, isCompleted: Bool = false) -> Task {
        Task(title: "T", category: .work, dateKey: dateKey, isCompleted: isCompleted)
    }

    private func monthPeriod() -> RecapCalculator.Period {
        let year = Calendar.current.component(.year, from: fixedNow)
        let month = Calendar.current.component(.month, from: fixedNow)
        return .month(year: year, month: month)
    }

    @Test func excludesIncompleteTodayAndFuture() {
        guard let yesterday = key(daysAgo: 1),
              let tomorrow = key(daysFromToday: 1) else {
            Issue.record("Missing date keys")
            return
        }

        let today = todayKey
        let tasks = [
            makeTask(dateKey: yesterday),
            makeTask(dateKey: today),
            makeTask(dateKey: tomorrow),
        ]

        let summary = RecapCalculator.calculate(
            allTasks: tasks,
            period: monthPeriod(),
            now: fixedNow
        )

        // Only yesterday counts; incomplete today excluded; tomorrow excluded as future.
        #expect(summary.totalAdded == 1)
    }

    @Test func includesTodayWhenAllComplete() {
        guard let yesterday = key(daysAgo: 1) else {
            Issue.record("Missing date keys")
            return
        }

        let today = todayKey
        let tasks = [
            makeTask(dateKey: yesterday, isCompleted: true),
            makeTask(dateKey: today, isCompleted: true),
            makeTask(dateKey: today, isCompleted: true),
        ]

        let summary = RecapCalculator.calculate(
            allTasks: tasks,
            period: monthPeriod(),
            now: fixedNow
        )

        #expect(summary.totalAdded == 3)
        #expect(summary.totalCompleted == 3)
    }

    @Test func excludesFutureRegardlessOfCompletion() {
        guard let tomorrow = key(daysFromToday: 1) else {
            Issue.record("Missing date keys")
            return
        }

        let tasks = [makeTask(dateKey: tomorrow, isCompleted: true)]

        let summary = RecapCalculator.calculate(
            allTasks: tasks,
            period: monthPeriod(),
            now: fixedNow
        )

        #expect(summary.totalAdded == 0)
    }

    @Test func groupsCustomProjectsByCategoryRaw() {
        guard let yesterday = key(daysAgo: 1) else {
            Issue.record("Missing date keys")
            return
        }

        let projectId = UUID()
        let raw = TaskCategoryKey.rawValue(projectId: projectId)

        let taskA = Task(title: "A", category: .other, dateKey: yesterday, isCompleted: true)
        taskA.categoryRaw = raw
        taskA.projectNameSnapshot = "Renovation"
        taskA.projectColorHexSnapshot = "#F59E0B"

        let taskB = Task(title: "B", category: .other, dateKey: yesterday, isCompleted: true)
        taskB.categoryRaw = raw
        taskB.projectNameSnapshot = "Renovation"
        taskB.projectColorHexSnapshot = "#F59E0B"

        let summary = RecapCalculator.calculate(
            allTasks: [taskA, taskB],
            period: monthPeriod(),
            now: fixedNow
        )

        #expect(summary.totalCompleted == 2)
        #expect(summary.byCategory.count == 1)
        #expect(summary.byCategory[0].groupKey == raw)
        #expect(summary.byCategory[0].completedCount == 2)
        #expect(summary.byCategory[0].displayName == "Renovation")
    }
}
