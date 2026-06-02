import Foundation
import SwiftData
@testable import ADHD_Figma

@MainActor
enum TestModelContainer {
    static func make() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Task.self, Project.self, configurations: config)
    }

    static func fetchAll(in context: ModelContext) throws -> [Task] {
        try context.fetch(FetchDescriptor<Task>())
    }
}
