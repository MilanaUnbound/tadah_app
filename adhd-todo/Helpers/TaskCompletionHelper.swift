import Foundation

enum TaskCompletionHelper {
    static func setCompleted(_ task: Task, completed: Bool) {
        task.isCompleted = completed
        task.completedAt = completed ? Date() : nil
    }

    static func toggle(_ task: Task) {
        setCompleted(task, completed: !task.isCompleted)
    }
}
