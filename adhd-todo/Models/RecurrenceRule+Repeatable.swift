import Foundation

extension RecurrenceRule {
    /// Rules selectable when Repeat is enabled (excludes `.none`).
    static let repeatableCases: [RecurrenceRule] = [.daily, .weekly, .custom]
}
