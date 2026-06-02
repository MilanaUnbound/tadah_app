import Foundation
import SwiftData
import Testing
@testable import ADHD_Figma

@MainActor
struct RecurrenceSeriesHelperTests {
    private let baseKey = "2026-05-25"

    private func makeSeriesTask(
        title: String,
        dateKey: String,
        seriesId: UUID,
        rule: RecurrenceRule = .daily
    ) -> Task {
        Task(
            title: title,
            category: .work,
            dateKey: dateKey,
            recurrenceRule: rule,
            recurrenceSeriesId: seriesId
        )
    }

    @Test func deleteUpcoming_removesFromSelectedDayForward() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let seriesId = UUID()

        for offset in 0..<5 {
            guard let key = DateHelpers.offsetKey(baseKey, byDays: offset) else {
                Issue.record("Missing offset key")
                return
            }
            context.insert(makeSeriesTask(title: "Series", dateKey: key, seriesId: seriesId))
        }

        let allBefore = try TestModelContainer.fetchAll(in: context)
        let dayThree = DateHelpers.offsetKey(baseKey, byDays: 2)!
        let pivot = allBefore.first { $0.dateKey == dayThree }!

        RecurrenceSeriesHelper.deleteUpcoming(for: pivot, from: allBefore, in: context)

        let remaining = try TestModelContainer.fetchAll(in: context)
        #expect(remaining.count == 2)
        #expect(remaining.allSatisfy { $0.dateKey < dayThree })
    }

    @Test func deleteUpcoming_leavesOtherSeries() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let seriesA = UUID()
        let seriesB = UUID()

        for offset in 0..<3 {
            guard let key = DateHelpers.offsetKey(baseKey, byDays: offset) else { return }
            context.insert(makeSeriesTask(title: "A", dateKey: key, seriesId: seriesA))
            context.insert(makeSeriesTask(title: "B", dateKey: key, seriesId: seriesB))
        }

        let allTasks = try TestModelContainer.fetchAll(in: context)
        let pivotKey = DateHelpers.offsetKey(baseKey, byDays: 1)!
        let pivotA = allTasks.first { $0.recurrenceSeriesId == seriesA && $0.dateKey == pivotKey }!

        RecurrenceSeriesHelper.deleteUpcoming(for: pivotA, from: allTasks, in: context)

        let remaining = try TestModelContainer.fetchAll(in: context)
        let remainingB = remaining.filter { $0.recurrenceSeriesId == seriesB }
        #expect(remainingB.count == 3)
    }

    @Test func deleteUpcoming_noOpWithoutSeriesId() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let seriesId = UUID()

        context.insert(makeSeriesTask(title: "Recurring", dateKey: baseKey, seriesId: seriesId))
        let solo = Task(title: "Solo", category: .other, dateKey: baseKey)
        context.insert(solo)

        let allTasks = try TestModelContainer.fetchAll(in: context)
        RecurrenceSeriesHelper.deleteUpcoming(for: solo, from: allTasks, in: context)

        let remaining = try TestModelContainer.fetchAll(in: context)
        #expect(remaining.count == 2)
    }

    @Test func singleDelete_leavesSiblingInstances() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let seriesId = UUID()

        for offset in 0..<3 {
            guard let key = DateHelpers.offsetKey(baseKey, byDays: offset) else { return }
            context.insert(makeSeriesTask(title: "Series", dateKey: key, seriesId: seriesId))
        }

        let allTasks = try TestModelContainer.fetchAll(in: context)
        let toRemove = allTasks.first { $0.dateKey == baseKey }!
        context.delete(toRemove)

        let remaining = try TestModelContainer.fetchAll(in: context)
        #expect(remaining.count == 2)
        #expect(remaining.allSatisfy { $0.recurrenceSeriesId == seriesId })
    }
}
