import Foundation
import SwiftUI

enum TaskCategoryKey {
    static let projectPrefix = "project:"

    static func rawValue(projectId: UUID) -> String {
        projectPrefix + projectId.uuidString
    }

    static func projectId(from categoryRaw: String) -> UUID? {
        guard categoryRaw.hasPrefix(projectPrefix) else { return nil }
        let uuidString = String(categoryRaw.dropFirst(projectPrefix.count))
        return UUID(uuidString: uuidString)
    }

    static func isBuiltin(_ categoryRaw: String) -> Bool {
        Category(rawValue: categoryRaw) != nil
    }
}

enum TaskCategoryDisplay {
    static func displayName(for task: Task, projects: [Project]) -> String {
        if let projectId = TaskCategoryKey.projectId(from: task.categoryRaw),
           let project = projects.first(where: { $0.id == projectId }) {
            return project.name
        }
        if let snapshot = task.projectNameSnapshot, snapshot.isEmpty == false {
            return snapshot
        }
        if let category = Category(rawValue: task.categoryRaw) {
            return category.displayName
        }
        return Category.other.displayName
    }

    static func displayColor(for task: Task, projects: [Project]) -> Color {
        if let projectId = TaskCategoryKey.projectId(from: task.categoryRaw),
           let project = projects.first(where: { $0.id == projectId }) {
            return Color(hex: project.colorHex) ?? Category.other.color
        }
        if let hex = task.projectColorHexSnapshot {
            return Color(hex: hex) ?? Category.other.color
        }
        if let category = Category(rawValue: task.categoryRaw) {
            return category.color
        }
        return Category.other.color
    }

    static func lightBackground(for task: Task, projects: [Project]) -> Color {
        displayColor(for: task, projects: projects).opacity(0.12)
    }

    static func breakdownInfo(
        forGroupKey groupKey: String,
        sampleTask: Task,
        projects: [Project]
    ) -> (displayName: String, colorHex: String) {
        if let category = Category(rawValue: groupKey) {
            return (category.displayName, category.colorHex)
        }
        if let projectId = TaskCategoryKey.projectId(from: groupKey),
           let project = projects.first(where: { $0.id == projectId }) {
            return (project.name, project.colorHex)
        }
        let name = sampleTask.projectNameSnapshot ?? "Project"
        let hex = sampleTask.projectColorHexSnapshot ?? ProjectColorCycle.defaultHex
        return (name, hex)
    }
}

private extension Category {
    var colorHex: String {
        switch self {
        case .work: "#7B2FFF"
        case .health: "#00C875"
        case .home: "#FF6B00"
        case .groceries: "#E8A800"
        case .social: "#FF3399"
        case .creative: "#E040FB"
        case .other: "#6B7280"
        }
    }
}

extension Color {
    init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
