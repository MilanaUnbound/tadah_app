import Foundation

enum DayCompletionHelper {
    static func normalTasks(from tasks: [Task]) -> [Task] {
        tasks.filter { $0.isBonus == false && $0.isDump == false }
    }

    static func allNormalTasksComplete(tasks: [Task]) -> Bool {
        let normal = normalTasks(from: tasks)
        guard normal.isEmpty == false else { return false }
        return normal.allSatisfy(\.isCompleted)
    }
}
