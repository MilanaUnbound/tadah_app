import Foundation
import SwiftData

enum TaskInsertOutcome: Equatable {
    case success
    case recurrenceFallback
}

enum TaskInsertHelper {
    static let recurrenceFailureMessage =
        "Couldn't set up repeat — task saved for today."

    @discardableResult
    static func insert(
        title: String,
        categorySelection: CategorySelection,
        scheduledDate: Date,
        recurrence: RecurrenceFormInput,
        into context: ModelContext
    ) -> TaskInsertOutcome {
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: scheduledDate)
        let dateKey = DateHelpers.dateKey(for: anchor)
        let placeholderCategory = categorySelection.builtinCategory ?? .other

        guard recurrence.isEnabled else {
            let task = Task(
                title: title,
                category: placeholderCategory,
                dateKey: dateKey,
                scheduledDate: anchor,
                recurrenceRule: .none,
                recurrenceSeriesId: nil
            )
            categorySelection.apply(to: task)
            context.insert(task)
            return .success
        }

        let seriesId = UUID()
        let result = RecurrenceGenerator.generate(
            title: title,
            categorySelection: categorySelection,
            anchorDate: anchor,
            rule: recurrence.rule,
            customWeekdays: recurrence.customWeekdays,
            seriesId: seriesId
        )

        switch result {
        case .success(let tasks):
            for task in tasks {
                context.insert(task)
            }
            return .success
        case .failure:
            let task = Task(
                title: title,
                category: placeholderCategory,
                dateKey: dateKey,
                scheduledDate: anchor,
                recurrenceRule: .none,
                recurrenceSeriesId: nil
            )
            categorySelection.apply(to: task)
            context.insert(task)
            return .recurrenceFallback
        }
    }
}
