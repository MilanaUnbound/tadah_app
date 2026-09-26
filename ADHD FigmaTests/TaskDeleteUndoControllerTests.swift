import Foundation
import SwiftData
import Testing
@testable import ADHD_Figma

@MainActor
struct TaskDeleteUndoControllerTests {
    private let baseKey = "2026-05-25"

    private func makeSeriesTask(
        title: String,
        dateKey: String,
        seriesId: UUID
    ) -> Task {
        Task(
            title: title,
            category: .work,
            dateKey: dateKey,
            recurrenceRule: .daily,
            recurrenceSeriesId: seriesId
        )
    }

    @Test func makeDeleteUpcomingSnapshot_capturesDeletedAndEarlierPatches() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let seriesId = UUID()

        for offset in 0..<5 {
            guard let key = DateHelpers.offsetKey(baseKey, byDays: offset) else { return }
            context.insert(makeSeriesTask(title: "Weekly lesson", dateKey: key, seriesId: seriesId))
        }

        let allTasks = try TestModelContainer.fetchAll(in: context)
        let pivotKey = DateHelpers.offsetKey(baseKey, byDays: 2)!
        let pivot = allTasks.first { $0.dateKey == pivotKey }!

        let snapshot = RecurrenceSeriesHelper.makeDeleteUpcomingSnapshot(for: pivot, from: allTasks)

        #expect(snapshot?.displayTitle == "Weekly lesson")
        #expect(snapshot?.representativeTaskID == pivot.id)
        #expect(snapshot?.deletedTasks.count == 3)
        #expect(snapshot?.earlierRecurrencePatches.count == 2)
    }

    @Test func deleteUpcoming_keepsTasksWhilePending_andUndoBeforeCommit() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let seriesId = UUID()

        for offset in 0..<5 {
            guard let key = DateHelpers.offsetKey(baseKey, byDays: offset) else { return }
            context.insert(makeSeriesTask(title: "Series", dateKey: key, seriesId: seriesId))
        }

        let allTasks = try TestModelContainer.fetchAll(in: context)
        let pivotKey = DateHelpers.offsetKey(baseKey, byDays: 2)!
        let pivot = allTasks.first { $0.dateKey == pivotKey }!

        let controller = TaskDeleteUndoController()
        controller.deleteUpcoming(for: pivot, from: allTasks, in: context)

        #expect(controller.isPendingDelete(taskID: pivot.id))
        #expect(controller.showsUndoSnackBar)
        #expect(try TestModelContainer.fetchAll(in: context).count == 5)

        controller.undo(in: context)

        #expect(controller.showsUndoSnackBar == false)
        #expect(controller.isPendingDelete(taskID: pivot.id) == false)
        #expect(try TestModelContainer.fetchAll(in: context).count == 5)
    }

    @Test func deleteUpcoming_commitRemovesSameTasksAsDirectDelete() async throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let seriesId = UUID()

        for offset in 0..<5 {
            guard let key = DateHelpers.offsetKey(baseKey, byDays: offset) else { return }
            context.insert(makeSeriesTask(title: "Series", dateKey: key, seriesId: seriesId))
        }

        let allTasks = try TestModelContainer.fetchAll(in: context)
        let pivotKey = DateHelpers.offsetKey(baseKey, byDays: 2)!
        let pivot = allTasks.first { $0.dateKey == pivotKey }!

        let controller = TaskDeleteUndoController()
        controller.deleteUpcoming(for: pivot, from: allTasks, in: context)

        try await Task.sleep(nanoseconds: 1_100_000_000)

        let remaining = try TestModelContainer.fetchAll(in: context)
        #expect(remaining.count == 2)
        #expect(remaining.allSatisfy { $0.dateKey < pivotKey })
        #expect(controller.showsUndoSnackBar)
        #expect(controller.isPendingDelete(taskID: pivot.id) == false)
    }

    @Test func deleteUpcoming_undoAfterCommitRestoresSeries() async throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext
        let seriesId = UUID()

        for offset in 0..<4 {
            guard let key = DateHelpers.offsetKey(baseKey, byDays: offset) else { return }
            context.insert(makeSeriesTask(title: "Series", dateKey: key, seriesId: seriesId))
        }

        let allTasks = try TestModelContainer.fetchAll(in: context)
        let pivotKey = DateHelpers.offsetKey(baseKey, byDays: 1)!
        let pivot = allTasks.first { $0.dateKey == pivotKey }!

        let controller = TaskDeleteUndoController()
        controller.deleteUpcoming(for: pivot, from: allTasks, in: context)

        try await Task.sleep(nanoseconds: 1_100_000_000)

        #expect(try TestModelContainer.fetchAll(in: context).count == 1)

        controller.undo(in: context)

        let restored = try TestModelContainer.fetchAll(in: context)
        #expect(restored.count == 4)
        #expect(restored.filter { $0.recurrenceSeriesId == seriesId }.count == 4)
        #expect(controller.showsUndoSnackBar == false)
    }
}
