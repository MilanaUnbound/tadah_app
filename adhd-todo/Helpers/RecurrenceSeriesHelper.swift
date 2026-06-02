import Foundation
import SwiftData

enum RecurrenceSeriesHelper {
    /// Deletes this instance and all later instances in the same series (F-013).
    static func deleteUpcoming(
        for task: Task,
        from allTasks: [Task],
        in context: ModelContext
    ) {
        guard let seriesId = task.recurrenceSeriesId else { return }
        let fromKey = task.dateKey

        let toDelete = allTasks.filter { candidate in
            guard candidate.recurrenceSeriesId == seriesId else { return false }
            return candidate.dateKey >= fromKey
        }

        for candidate in toDelete {
            context.delete(candidate)
        }
    }
}
