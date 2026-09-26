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
        isBonus: Bool = false,
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
                isBonus: isBonus,
                scheduledDate: anchor,
                recurrenceRule: .none,
                recurrenceSeriesId: nil
            )
            task.sortOrder = TaskReorderHelper.nextSortOrder(
                for: dateKey,
                isBonus: isBonus,
                in: context
            )
            categorySelection.apply(to: task)
            context.insert(task)
            return .success
        }

        let seriesId = UUID()
        let untilDate: Date?
        switch recurrence.end {
        case .none:
            untilDate = nil
        case .until(let date):
            untilDate = calendar.startOfDay(for: date)
        }
        let result = RecurrenceGenerator.generate(
            title: title,
            categorySelection: categorySelection,
            isBonus: isBonus,
            anchorDate: anchor,
            rule: recurrence.rule,
            customWeekdays: recurrence.customWeekdays,
            untilDate: untilDate,
            seriesId: seriesId
        )

        switch result {
        case .success(let tasks):
            var nextOrderByBucket: [String: Int] = [:]
            for task in tasks {
                let bucketKey = "\(task.dateKey)|\(task.isBonus)"
                if nextOrderByBucket[bucketKey] == nil {
                    nextOrderByBucket[bucketKey] = TaskReorderHelper.nextSortOrder(
                        for: task.dateKey,
                        isBonus: task.isBonus,
                        in: context
                    )
                }
                task.sortOrder = nextOrderByBucket[bucketKey]!
                nextOrderByBucket[bucketKey]! += 1
                context.insert(task)
            }
            return .success
        case .failure:
            let task = Task(
                title: title,
                category: placeholderCategory,
                dateKey: dateKey,
                isBonus: isBonus,
                scheduledDate: anchor,
                recurrenceRule: .none,
                recurrenceSeriesId: nil
            )
            task.sortOrder = TaskReorderHelper.nextSortOrder(
                for: dateKey,
                isBonus: isBonus,
                in: context
            )
            categorySelection.apply(to: task)
            context.insert(task)
            return .recurrenceFallback
        }
    }
}
