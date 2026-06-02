import Foundation
import Testing
@testable import ADHD_Figma

struct TaskCompletionHelperTests {
    @Test func setCompleted_setsAndClearsCompletedAt() {
        let task = Task(title: "T", category: .work, dateKey: "2026-05-01")

        TaskCompletionHelper.setCompleted(task, completed: true)
        #expect(task.isCompleted)
        #expect(task.completedAt != nil)

        TaskCompletionHelper.setCompleted(task, completed: false)
        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }

    @Test func toggle_flipsState() {
        let task = Task(title: "T", category: .health, dateKey: "2026-05-01")
        #expect(task.isCompleted == false)

        TaskCompletionHelper.toggle(task)
        #expect(task.isCompleted)
        #expect(task.completedAt != nil)

        TaskCompletionHelper.toggle(task)
        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }
}
