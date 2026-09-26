import Foundation
import SwiftData
import SwiftUI

@Observable
final class TaskDeleteUndoController {
    var pendingUndo: TaskUndoSnapshot?
    var pendingSeriesUndo: RecurrenceDeleteUndoSnapshot?
    var pendingDeleteTaskID: UUID?

    var displayTitle: String {
        pendingUndo?.title ?? pendingSeriesUndo?.displayTitle ?? ""
    }

    var showsUndoSnackBar: Bool {
        pendingUndo != nil || pendingSeriesUndo != nil
    }

    private var pendingTask: Task?
    private var pendingSeriesPivot: Task?
    private var commitDeleteTask: _Concurrency.Task<Void, Never>?
    private var dismissUndoTask: _Concurrency.Task<Void, Never>?

    /// Row stays visible with pending-delete styling until the task is removed from the store.
    private static let commitDeleteDelayNanoseconds: UInt64 = 1_000_000_000
    /// Undo snackbar stays available for this long after delete (even after the row is gone).
    private static let undoDismissDelayNanoseconds: UInt64 = 4_000_000_000

    func isPendingDelete(taskID: UUID) -> Bool {
        pendingDeleteTaskID == taskID
    }

    func delete(_ task: Task, in modelContext: ModelContext) {
        cancelTimers()
        commitAnyPending(in: modelContext)

        pendingTask = task
        pendingDeleteTaskID = task.id
        pendingUndo = TaskUndoSnapshot(task: task)
        scheduleTimers(in: modelContext)
    }

    func deleteUpcoming(for task: Task, from allTasks: [Task], in modelContext: ModelContext) {
        cancelTimers()
        commitAnyPending(in: modelContext)

        guard let snapshot = RecurrenceSeriesHelper.makeDeleteUpcomingSnapshot(
            for: task,
            from: allTasks
        ) else { return }

        pendingSeriesPivot = task
        pendingDeleteTaskID = task.id
        pendingSeriesUndo = snapshot
        scheduleTimers(in: modelContext)
    }

    func undo(in modelContext: ModelContext) {
        cancelTimers()

        if pendingTask != nil {
            clearPendingVisualState()
            pendingUndo = nil
            return
        }

        if pendingSeriesPivot != nil {
            clearPendingVisualState()
            pendingSeriesUndo = nil
            return
        }

        if let snapshot = pendingUndo {
            withAnimation(.easeOut(duration: 0.15)) {
                snapshot.insert(into: modelContext)
            }
            pendingUndo = nil
            return
        }

        if let seriesSnapshot = pendingSeriesUndo {
            let allTasks = fetchAllTasks(in: modelContext)
            withAnimation(.easeOut(duration: 0.15)) {
                seriesSnapshot.restore(into: modelContext, existingTasks: allTasks)
            }
            pendingSeriesUndo = nil
        }
    }

    func dismiss() {
        cancelTimers()
        clearAllState()
    }

    private func scheduleTimers(in modelContext: ModelContext) {
        commitDeleteTask = _Concurrency.Task { @MainActor in
            try? await _Concurrency.Task.sleep(nanoseconds: Self.commitDeleteDelayNanoseconds)
            guard !_Concurrency.Task.isCancelled else { return }
            commitAnyPending(in: modelContext)
        }

        dismissUndoTask = _Concurrency.Task { @MainActor in
            try? await _Concurrency.Task.sleep(nanoseconds: Self.undoDismissDelayNanoseconds)
            guard !_Concurrency.Task.isCancelled else { return }
            dismissUndoSnackBar()
        }
    }

    private func commitAnyPending(in modelContext: ModelContext) {
        if pendingTask != nil {
            commitPendingSingleDelete(in: modelContext)
        } else if pendingSeriesPivot != nil {
            commitPendingSeriesDelete(in: modelContext)
        }
    }

    private func commitPendingSingleDelete(in modelContext: ModelContext) {
        withAnimation(.easeOut(duration: 0.15)) {
            if let task = pendingTask {
                modelContext.delete(task)
            }
            pendingTask = nil
            pendingDeleteTaskID = nil
        }
    }

    private func commitPendingSeriesDelete(in modelContext: ModelContext) {
        guard let pivot = pendingSeriesPivot else { return }
        let allTasks = fetchAllTasks(in: modelContext)
        withAnimation(.easeOut(duration: 0.15)) {
            RecurrenceSeriesHelper.deleteUpcoming(for: pivot, from: allTasks, in: modelContext)
            pendingSeriesPivot = nil
            pendingDeleteTaskID = nil
        }
    }

    private func dismissUndoSnackBar() {
        withAnimation(.easeOut(duration: 0.15)) {
            pendingUndo = nil
            pendingSeriesUndo = nil
        }
    }

    private func clearPendingVisualState() {
        pendingTask = nil
        pendingSeriesPivot = nil
        pendingDeleteTaskID = nil
    }

    private func clearAllState() {
        clearPendingVisualState()
        pendingUndo = nil
        pendingSeriesUndo = nil
    }

    private func cancelTimers() {
        commitDeleteTask?.cancel()
        commitDeleteTask = nil
        dismissUndoTask?.cancel()
        dismissUndoTask = nil
    }

    private func fetchAllTasks(in modelContext: ModelContext) -> [Task] {
        (try? modelContext.fetch(FetchDescriptor<Task>())) ?? []
    }
}
