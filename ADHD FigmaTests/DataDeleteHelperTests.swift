import Foundation
import SwiftData
import Testing
@testable import ADHD_Figma

@MainActor
struct DataDeleteHelperTests {
    @Test func deleteAll_removesTasksAndProjects() throws {
        let container = try TestModelContainer.make()
        let context = container.mainContext

        context.insert(Project(name: "Side project", colorHex: "#7B2FFF"))
        context.insert(Task(title: "Test task", category: .work, dateKey: DateHelpers.todayKey()))
        try context.save()

        UpcomingOrderStore.save(["task-1"])

        try DataDeleteHelper.deleteAll(in: context)

        let tasks = try TestModelContainer.fetchAll(in: context)
        let projects = try context.fetch(FetchDescriptor<Project>())

        #expect(tasks.isEmpty)
        #expect(projects.isEmpty)
        #expect(UpcomingOrderStore.load().isEmpty)
    }
}
