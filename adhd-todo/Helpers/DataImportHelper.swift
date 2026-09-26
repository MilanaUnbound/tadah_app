import Foundation
import SwiftData

enum DataImportHelper {
    enum ImportError: LocalizedError {
        case invalidFormat
        case unreadableFile

        var errorDescription: String? {
            switch self {
            case .invalidFormat, .unreadableFile:
                "Invalid backup file."
            }
        }
    }

    static func decode(from url: URL) throws -> ExportBundle {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.unreadableFile
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let bundle = try? decoder.decode(ExportBundle.self, from: data) {
            return bundle
        }

        throw ImportError.invalidFormat
    }

    static func replaceAll(bundle: ExportBundle, in context: ModelContext) throws {
        let existingTasks = try context.fetch(FetchDescriptor<Task>())
        for task in existingTasks {
            context.delete(task)
        }

        let existingProjects = try context.fetch(FetchDescriptor<Project>())
        for project in existingProjects {
            context.delete(project)
        }

        for projectExport in bundle.projects {
            let project = Project(
                id: projectExport.id,
                name: projectExport.name,
                colorHex: projectExport.colorHex,
                createdAt: projectExport.createdAt
            )
            context.insert(project)
        }

        for todo in bundle.todos {
            let category: Category
            if TaskCategoryKey.isBuiltin(todo.categoryRaw), let parsed = Category(rawValue: todo.categoryRaw) {
                category = parsed
            } else {
                category = .other
            }

            let recurrenceRule = RecurrenceRule(rawValue: todo.recurrenceRuleRaw ?? "") ?? .none

            let task = Task(
                id: todo.id,
                title: todo.title,
                category: category,
                dateKey: todo.dateKey,
                isCompleted: todo.isCompleted,
                isBonus: todo.isBonus,
                completedAt: todo.completedAt,
                scheduledDate: todo.scheduledDate,
                recurrenceRule: recurrenceRule,
                recurrenceSeriesId: todo.recurrenceSeriesId,
                customWeekdaysMask: todo.customWeekdaysMask,
                projectNameSnapshot: todo.projectNameSnapshot,
                projectColorHexSnapshot: todo.projectColorHexSnapshot
            )
            task.categoryRaw = todo.categoryRaw
            task.sortOrder = todo.sortOrder ?? 0
            context.insert(task)
        }

        try context.save()
    }
}
