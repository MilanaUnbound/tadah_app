import SwiftData

enum DataDeleteHelper {
    static func deleteAll(in context: ModelContext) throws {
        let existingTasks = try context.fetch(FetchDescriptor<Task>())
        for task in existingTasks {
            context.delete(task)
        }

        let existingProjects = try context.fetch(FetchDescriptor<Project>())
        for project in existingProjects {
            context.delete(project)
        }

        try context.save()
        UpcomingOrderStore.clear()
    }
}
