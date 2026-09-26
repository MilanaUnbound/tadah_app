import Foundation

/// Repeat settings collected from the add task form (F-013).
struct RecurrenceFormInput: Equatable {
    enum RecurrenceEnd: Equatable {
        case none
        /// Date-only (start-of-day).
        case until(Date)
    }

    let isEnabled: Bool
    let rule: RecurrenceRule
    /// `Calendar` weekday values (1 = Sunday … 7 = Saturday).
    let customWeekdays: Set<Int>
    let end: RecurrenceEnd

    static let disabled = RecurrenceFormInput(isEnabled: false, rule: .none, customWeekdays: [], end: .none)
}
