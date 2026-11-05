import Foundation
import SwiftData
import SwiftUI

@Observable
final class RescheduleController {
    var taskID: UUID?

    func present(task: Task) {
        taskID = task.id
    }

    func dismiss() {
        taskID = nil
    }

    func apply(
        result: ScheduleSheetResult,
        task: Task,
        allTasks: [Task],
        projects: [Project],
        in context: ModelContext
    ) {
        withAnimation(.easeOut(duration: 0.15)) {
            if task.isRecurringInstance, result.scope == .allUpcoming, let input = result.recurrenceInput {
                RecurrenceSeriesHelper.updateUpcoming(
                    from: task,
                    anchorDate: result.selectedDate,
                    input: input,
                    allTasks: allTasks,
                    projects: projects,
                    in: context
                )
            } else {
                moveSingle(task: task, to: result.selectedDate)
            }
        }
        dismiss()
    }

    private func moveSingle(task: Task, to newDate: Date) {
        let start = Calendar.current.startOfDay(for: newDate)
        task.dateKey = DateHelpers.dateKey(for: start)
        task.scheduledDate = start
        task.isDump = false
    }
}
