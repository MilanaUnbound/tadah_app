import Foundation

/// How a task repeats after it is saved (F-013). Stored on `Task` as a raw string for SwiftData.
enum RecurrenceRule: String, CaseIterable, Identifiable, Codable {
    case none
    case daily
    case weekly
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "Does not repeat"
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .custom: "Custom days"
        }
    }
}
