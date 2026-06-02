import Foundation

enum CategorySelection {
    case builtin(Category)
    case project(Project)

    func apply(to task: Task) {
        switch self {
        case .builtin(let category):
            task.categoryRaw = category.rawValue
            task.projectNameSnapshot = nil
            task.projectColorHexSnapshot = nil
        case .project(let project):
            task.categoryRaw = TaskCategoryKey.rawValue(projectId: project.id)
            task.projectNameSnapshot = project.name
            task.projectColorHexSnapshot = project.colorHex
        }
    }

    var builtinCategory: Category? {
        if case .builtin(let category) = self { return category }
        return nil
    }
}

extension CategorySelection: Equatable {
    static func == (lhs: CategorySelection, rhs: CategorySelection) -> Bool {
        switch (lhs, rhs) {
        case (.builtin(let a), .builtin(let b)):
            return a == b
        case (.project(let a), .project(let b)):
            return a.id == b.id
        default:
            return false
        }
    }
}
