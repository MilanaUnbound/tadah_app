import Foundation
import SwiftData

enum ScheduleEditScope: Equatable, Hashable {
    case thisDateOnly
    case allUpcoming
}

struct ScheduleSheetResult: Equatable {
    let selectedDate: Date
    let scope: ScheduleEditScope?
    let recurrenceInput: RecurrenceFormInput?
}

enum RecurrenceSeriesHelper {
    /// Builds a snapshot of state that `deleteUpcoming` would change, without mutating the store.
    static func makeDeleteUpcomingSnapshot(
        for task: Task,
        from allTasks: [Task]
    ) -> RecurrenceDeleteUndoSnapshot? {
        guard let seriesId = task.recurrenceSeriesId else { return nil }
        let fromKey = task.dateKey

        let toDelete = allTasks.filter { candidate in
            guard candidate.recurrenceSeriesId == seriesId else { return false }
            return candidate.dateKey >= fromKey
        }

        let earlier = allTasks.filter { candidate in
            guard candidate.recurrenceSeriesId == seriesId else { return false }
            return candidate.dateKey < fromKey
        }

        return RecurrenceDeleteUndoSnapshot(
            displayTitle: task.title,
            representativeTaskID: task.id,
            deletedTasks: toDelete.map(TaskUndoSnapshot.init(task:)),
            earlierRecurrencePatches: earlier.map { candidate in
                EarlierRecurrencePatch(
                    taskID: candidate.id,
                    recurrenceRuleRaw: candidate.recurrenceRuleRaw,
                    recurrenceSeriesId: candidate.recurrenceSeriesId,
                    customWeekdaysMask: candidate.customWeekdaysMask
                )
            }
        )
    }

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

        let remainingEarlier = allTasks.filter { candidate in
            guard candidate.recurrenceSeriesId == seriesId else { return false }
            return candidate.dateKey < fromKey
        }

        for candidate in remainingEarlier {
            candidate.recurrenceSeriesId = nil
            candidate.recurrenceRuleRaw = nil
            candidate.customWeekdaysMask = nil
        }
    }

    static func weekdays(from mask: Int?) -> Set<Int> {
        guard let mask else { return [] }
        var result = Set<Int>()
        for weekday in 1...7 {
            if (mask & (1 << (weekday - 1))) != 0 {
                result.insert(weekday)
            }
        }
        return result
    }

    static func inferFormInput(for task: Task, seriesTasks: [Task]) -> RecurrenceFormInput {
        let rule = task.recurrenceRule == .none ? .weekly : task.recurrenceRule
        let weekdays = weekdays(from: task.customWeekdaysMask)
        let sorted = seriesTasks.sorted { $0.dateKey < $1.dateKey }

        var end: RecurrenceFormInput.RecurrenceEnd = .none
        if let maxKey = sorted.last?.dateKey,
           let maxDate = DateHelpers.startOfDay(forKey: maxKey),
           let minKey = sorted.first?.dateKey,
           let minDate = DateHelpers.startOfDay(forKey: minKey),
           let horizonEnd = Calendar.current.date(
               byAdding: .day,
               value: RecurrenceGenerator.defaultHorizonDays - 1,
               to: minDate
           ),
           maxDate < horizonEnd {
            end = .until(maxDate)
        }

        return RecurrenceFormInput(
            isEnabled: true,
            rule: rule,
            customWeekdays: weekdays,
            end: end
        )
    }

    static func seriesTasks(for task: Task, from allTasks: [Task]) -> [Task] {
        guard let seriesId = task.recurrenceSeriesId else { return [task] }
        return allTasks.filter { $0.recurrenceSeriesId == seriesId }
    }

    static func categorySelection(for task: Task, projects: [Project]) -> CategorySelection {
        if let projectId = TaskCategoryKey.projectId(from: task.categoryRaw),
           let project = projects.first(where: { $0.id == projectId }) {
            return .project(project)
        }
        return .builtin(task.category)
    }

    /// Regenerates incomplete instances from `task.dateKey` forward with new repeat settings.
    static func updateUpcoming(
        from task: Task,
        anchorDate: Date,
        input: RecurrenceFormInput,
        allTasks: [Task],
        projects: [Project],
        in context: ModelContext
    ) {
        guard let seriesId = task.recurrenceSeriesId else { return }
        guard input.isEnabled, input.rule != .none else { return }
        if input.rule == .custom && input.customWeekdays.isEmpty { return }

        let cutoff = task.dateKey
        let categorySelection = categorySelection(for: task, projects: projects)
        let completedKeys = Set(
            allTasks
                .filter { $0.recurrenceSeriesId == seriesId && $0.isCompleted }
                .map(\.dateKey)
        )

        let toDelete = allTasks.filter { candidate in
            candidate.recurrenceSeriesId == seriesId
                && candidate.isCompleted == false
                && candidate.dateKey >= cutoff
        }
        let deletedIDs = Set(toDelete.map(\.id))
        for candidate in toDelete {
            context.delete(candidate)
        }

        let untilDate: Date?
        switch input.end {
        case .none:
            untilDate = nil
        case .until(let date):
            untilDate = Calendar.current.startOfDay(for: date)
        }

        let calendar = Calendar.current
        let anchor = max(
            DateHelpers.startOfToday(),
            calendar.startOfDay(for: anchorDate)
        )

        guard case .success(let generated) = RecurrenceGenerator.generate(
            title: task.title,
            categorySelection: categorySelection,
            isBonus: task.isBonus,
            anchorDate: anchor,
            rule: input.rule,
            customWeekdays: input.customWeekdays,
            untilDate: untilDate,
            seriesId: seriesId
        ) else {
            return
        }

        let mask = input.rule == .custom
            ? RecurrenceGenerator.weekdaysMask(input.customWeekdays)
            : nil

        for newTask in generated where newTask.dateKey >= cutoff {
            guard completedKeys.contains(newTask.dateKey) == false else { continue }
            newTask.sortOrder = TaskReorderHelper.nextSortOrder(
                for: newTask.dateKey,
                isBonus: newTask.isBonus,
                in: context
            )
            context.insert(newTask)
        }

        for remaining in allTasks where remaining.recurrenceSeriesId == seriesId && deletedIDs.contains(remaining.id) == false {
            remaining.recurrenceRuleRaw = input.rule.rawValue
            remaining.customWeekdaysMask = mask
        }
    }
}
