import Foundation
import SwiftUI

enum CategoryPickerTarget {
    case task(UUID)
    case bulk(sourceCategoryRaw: String)
}

struct CategoryPickerContext: Identifiable {
    let id = UUID()
    let target: CategoryPickerTarget
    let currentCategoryRaw: String

    var isBulk: Bool {
        if case .bulk = target { return true }
        return false
    }
}

@Observable
final class CategoryPickerController {
    var context: CategoryPickerContext?

    func present(task: Task) {
        context = CategoryPickerContext(
            target: .task(task.id),
            currentCategoryRaw: task.categoryRaw
        )
    }

    func presentBulk(sourceCategoryRaw: String) {
        context = CategoryPickerContext(
            target: .bulk(sourceCategoryRaw: sourceCategoryRaw),
            currentCategoryRaw: sourceCategoryRaw
        )
    }

    func dismiss() {
        context = nil
    }

    func apply(_ selection: CategorySelection, tasks: [Task]) {
        guard let context else { return }

        withAnimation(.easeOut(duration: 0.15)) {
            switch context.target {
            case .task(let taskID):
                if let task = tasks.first(where: { $0.id == taskID }) {
                    selection.apply(to: task)
                }
            case .bulk(let sourceCategoryRaw):
                for task in tasks where task.categoryRaw == sourceCategoryRaw {
                    selection.apply(to: task)
                }
            }
        }
        dismiss()
    }
}
