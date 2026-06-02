import Foundation
import SwiftData
import Testing
@testable import ADHD_Figma

@MainActor
struct TaskInsertHelperTests {
    private let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func singleTask_scheduledTomorrow_usesTomorrowDateKey() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext

        let todayKey = DateHelpers.todayKey(now: fixedNow)
        guard let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: fixedNow),
              let tomorrowKey = DateHelpers.offsetKey(todayKey, byDays: 1) else {
            Issue.record("Missing tomorrow")
            return
        }

        let outcome = TaskInsertHelper.insert(
            title: "Future task",
            categorySelection: .builtin(.work),
            scheduledDate: tomorrowDate,
            recurrence: .disabled,
            into: context
        )

        #expect(outcome == .success)

        let tasks = try TestModelContainer.fetchAll(in: context)
        #expect(tasks.count == 1)
        #expect(tasks[0].dateKey == tomorrowKey)
        #expect(tasks[0].dateKey != todayKey)
    }

    @Test func dailyRepeat_insertsSixtyTasks() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext

        let recurrence = RecurrenceFormInput(
            isEnabled: true,
            rule: .daily,
            customWeekdays: []
        )

        let outcome = TaskInsertHelper.insert(
            title: "Daily habit",
            categorySelection: .builtin(.health),
            scheduledDate: fixedNow,
            recurrence: recurrence,
            into: context
        )

        #expect(outcome == .success)

        let tasks = try TestModelContainer.fetchAll(in: context)
        #expect(tasks.count == 60)
        #expect(Set(tasks.map(\.recurrenceSeriesId)).count == 1)
    }

    @Test func projectSelection_setsProjectCategoryRawAndSnapshots() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext

        let project = Project(name: "Renovation", colorHex: "#F59E0B")
        context.insert(project)

        let outcome = TaskInsertHelper.insert(
            title: "Buy paint",
            categorySelection: .project(project),
            scheduledDate: fixedNow,
            recurrence: .disabled,
            into: context
        )

        #expect(outcome == .success)

        let tasks = try TestModelContainer.fetchAll(in: context)
        #expect(tasks.count == 1)
        #expect(tasks[0].categoryRaw == TaskCategoryKey.rawValue(projectId: project.id))
        #expect(tasks[0].projectNameSnapshot == "Renovation")
        #expect(tasks[0].projectColorHexSnapshot == "#F59E0B")
    }
}
