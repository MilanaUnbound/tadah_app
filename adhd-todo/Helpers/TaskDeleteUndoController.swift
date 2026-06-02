import Foundation
import SwiftData
import SwiftUI

@Observable
final class TaskDeleteUndoController {
    var pendingUndo: TaskUndoSnapshot?
    var pendingDeleteTaskID: UUID?

    var displayTitle: String {
        pendingUndo?.title ?? ""
    }

    private var pendingTask: Task?
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

        if let previous = pendingTask {
            withAnimation(.easeOut(duration: 0.15)) {
                modelContext.delete(previous)
            }
        }

        pendingTask = task
        pendingDeleteTaskID = task.id
        pendingUndo = TaskUndoSnapshot(task: task)
        scheduleTimers(in: modelContext)
    }

    func undo(in modelContext: ModelContext) {
        guard let snapshot = pendingUndo else { return }
        cancelTimers()

        if pendingTask != nil {
            clearPendingVisualState()
        } else {
            withAnimation(.easeOut(duration: 0.15)) {
                snapshot.insert(into: modelContext)
            }
        }
        pendingUndo = nil
    }

    func dismiss() {
        cancelTimers()
        clearAllState()
    }

    private func scheduleTimers(in modelContext: ModelContext) {
        commitDeleteTask = _Concurrency.Task { @MainActor in
            try? await _Concurrency.Task.sleep(nanoseconds: Self.commitDeleteDelayNanoseconds)
            guard !_Concurrency.Task.isCancelled else { return }
            commitPendingDelete(in: modelContext)
        }

        dismissUndoTask = _Concurrency.Task { @MainActor in
            try? await _Concurrency.Task.sleep(nanoseconds: Self.undoDismissDelayNanoseconds)
            guard !_Concurrency.Task.isCancelled else { return }
            dismissUndoSnackBar()
        }
    }

    private func commitPendingDelete(in modelContext: ModelContext) {
        withAnimation(.easeOut(duration: 0.15)) {
            if let task = pendingTask {
                modelContext.delete(task)
            }
            clearPendingVisualState()
        }
    }

    private func dismissUndoSnackBar() {
        withAnimation(.easeOut(duration: 0.15)) {
            pendingUndo = nil
        }
    }

    private func clearPendingVisualState() {
        pendingTask = nil
        pendingDeleteTaskID = nil
    }

    private func clearAllState() {
        clearPendingVisualState()
        pendingUndo = nil
    }

    private func cancelTimers() {
        commitDeleteTask?.cancel()
        commitDeleteTask = nil
        dismissUndoTask?.cancel()
        dismissUndoTask = nil
    }
}
