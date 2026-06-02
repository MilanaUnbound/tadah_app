import SwiftUI

enum CategoryPickerOption: Identifiable {
    case builtin(Category)
    case project(Project)

    var id: String { categoryRaw }

    var categoryRaw: String {
        switch self {
        case .builtin(let category):
            return category.rawValue
        case .project(let project):
            return TaskCategoryKey.rawValue(projectId: project.id)
        }
    }

    var displayName: String {
        switch self {
        case .builtin(let category):
            return category.displayName
        case .project(let project):
            return project.name
        }
    }

    var color: Color {
        switch self {
        case .builtin(let category):
            return category.color
        case .project(let project):
            return Color(hex: project.colorHex) ?? Category.other.color
        }
    }

    var categorySelection: CategorySelection {
        switch self {
        case .builtin(let category):
            return .builtin(category)
        case .project(let project):
            return .project(project)
        }
    }

    static func allOptions(projects: [Project]) -> [CategoryPickerOption] {
        Category.allCases.map { .builtin($0) }
            + projects.map { .project($0) }
    }
}
