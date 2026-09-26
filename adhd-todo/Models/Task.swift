import Foundation
import SwiftData

@Model
final class Task {
    var id: UUID
    var title: String
    var categoryRaw: String
    /// The calendar day this task instance belongs to (YYYY-MM-DD, local).
    var dateKey: String
    var isCompleted: Bool
    var isBonus: Bool

    /// Display order within a day + bonus bucket (Today reorder).
    var sortOrder: Int = 0

    /// When the task was marked complete (History browse). Cleared when marked incomplete.
    var completedAt: Date?

    /// User-selected schedule date (F-012). `nil` on legacy rows → treated as start of `dateKey` day.
    var scheduledDate: Date?

    /// Recurrence template rule (F-013). `nil` on legacy rows → `.none`.
    var recurrenceRuleRaw: String?

    /// Links materialized instances from one repeat save (F-013).
    var recurrenceSeriesId: UUID?

    /// Bitmask of `Calendar` weekday (1…7) when rule is `.custom`.
    var customWeekdaysMask: Int?

    /// Display name when `categoryRaw` is `project:<uuid>` (survives project deletion).
    var projectNameSnapshot: String?

    /// Display color when `categoryRaw` is `project:<uuid>` (survives project deletion).
    var projectColorHexSnapshot: String?

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var recurrenceRule: RecurrenceRule {
        get { RecurrenceRule(rawValue: recurrenceRuleRaw ?? "") ?? .none }
        set { recurrenceRuleRaw = newValue.rawValue }
    }

    var isRecurringInstance: Bool { recurrenceSeriesId != nil }

    var showsRepeatIcon: Bool { isRecurringInstance }

    /// Resolved schedule date (defaults to start of `dateKey` day).
    var resolvedScheduledDate: Date {
        scheduledDate
            ?? DateHelpers.startOfDay(forKey: dateKey)
            ?? Calendar.current.startOfDay(for: Date())
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: Category,
        dateKey: String,
        isCompleted: Bool = false,
        isBonus: Bool = false,
        completedAt: Date? = nil,
        scheduledDate: Date? = nil,
        recurrenceRule: RecurrenceRule = .none,
        recurrenceSeriesId: UUID? = nil,
        customWeekdaysMask: Int? = nil,
        projectNameSnapshot: String? = nil,
        projectColorHexSnapshot: String? = nil
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.dateKey = dateKey
        self.isCompleted = isCompleted
        self.isBonus = isBonus
        self.completedAt = completedAt
        self.scheduledDate = scheduledDate
            ?? DateHelpers.startOfDay(forKey: dateKey)
            ?? Calendar.current.startOfDay(for: Date())
        self.recurrenceRuleRaw = recurrenceRule.rawValue
        self.recurrenceSeriesId = recurrenceSeriesId
        self.customWeekdaysMask = customWeekdaysMask
        self.projectNameSnapshot = projectNameSnapshot
        self.projectColorHexSnapshot = projectColorHexSnapshot
    }
}
