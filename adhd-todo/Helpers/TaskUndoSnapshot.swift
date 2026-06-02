import Foundation
import SwiftData

struct TaskUndoSnapshot {
    let id: UUID
    let title: String
    let categoryRaw: String
    let dateKey: String
    let isCompleted: Bool
    let completedAt: Date?
    let scheduledDate: Date?
    let recurrenceRuleRaw: String?
    let recurrenceSeriesId: UUID?
    let customWeekdaysMask: Int?
    let projectNameSnapshot: String?
    let projectColorHexSnapshot: String?

    init(task: Task) {
        id = task.id
        title = task.title
        categoryRaw = task.categoryRaw
        dateKey = task.dateKey
        isCompleted = task.isCompleted
        completedAt = task.completedAt
        scheduledDate = task.scheduledDate
        recurrenceRuleRaw = task.recurrenceRuleRaw
        recurrenceSeriesId = task.recurrenceSeriesId
        customWeekdaysMask = task.customWeekdaysMask
        projectNameSnapshot = task.projectNameSnapshot
        projectColorHexSnapshot = task.projectColorHexSnapshot
    }

    func insert(into modelContext: ModelContext) {
        let placeholderCategory = Category(rawValue: categoryRaw) ?? .other
        let recurrenceRule = RecurrenceRule(rawValue: recurrenceRuleRaw ?? "") ?? .none

        let restored = Task(
            id: id,
            title: title,
            category: placeholderCategory,
            dateKey: dateKey,
            isCompleted: isCompleted,
            completedAt: completedAt,
            scheduledDate: scheduledDate,
            recurrenceRule: recurrenceRule,
            recurrenceSeriesId: recurrenceSeriesId,
            customWeekdaysMask: customWeekdaysMask,
            projectNameSnapshot: projectNameSnapshot,
            projectColorHexSnapshot: projectColorHexSnapshot
        )
        restored.categoryRaw = categoryRaw
        restored.recurrenceRuleRaw = recurrenceRuleRaw
        modelContext.insert(restored)
    }
}
