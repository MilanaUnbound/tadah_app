import Foundation

/// Repeat settings collected from the add task form (F-013).
struct RecurrenceFormInput: Equatable {
    let isEnabled: Bool
    let rule: RecurrenceRule
    /// `Calendar` weekday values (1 = Sunday … 7 = Saturday).
    let customWeekdays: Set<Int>

    static let disabled = RecurrenceFormInput(isEnabled: false, rule: .none, customWeekdays: [])
}
