import Foundation
import SwiftData

enum TaskReorderHelper {
    private static func bucketKey(dateKey: String, isBonus: Bool) -> String {
        "\(dateKey)|\(isBonus)"
    }

    /// Backfill legacy rows that share `sortOrder == 0`, or fix duplicate order values.
    static func normalizeSortOrders(_ tasks: [Task]) {
        let grouped = Dictionary(grouping: tasks) { bucketKey(dateKey: $0.dateKey, isBonus: $0.isBonus) }

        for (_, bucket) in grouped {
            guard bucket.count > 1 else { continue }

            let sorted = bucket.sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }

            let allZero = sorted.allSatisfy { $0.sortOrder == 0 }
            let hasDuplicates = Set(sorted.map(\.sortOrder)).count < sorted.count

            guard allZero || hasDuplicates else { continue }

            for (index, task) in sorted.enumerated() {
                task.sortOrder = index
            }
        }
    }

    static func nextSortOrder(
        for dateKey: String,
        isBonus: Bool,
        in context: ModelContext
    ) -> Int {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { task in
                task.dateKey == dateKey && task.isBonus == isBonus
            }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        return (existing.map(\.sortOrder).max() ?? -1) + 1
    }

    static func move(taskID: UUID, toIndex: Int, in tasks: [Task]) {
        guard let sourceIndex = tasks.firstIndex(where: { $0.id == taskID }) else { return }

        var reordered = tasks
        let moved = reordered.remove(at: sourceIndex)
        let clampedIndex = min(max(0, toIndex), reordered.count)
        reordered.insert(moved, at: clampedIndex)

        for (index, task) in reordered.enumerated() {
            task.sortOrder = index
        }
    }
}
