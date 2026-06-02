import SwiftUI
import SwiftData

@main
struct adhd_todoApp: App {
    private let container: ModelContainer = {
        do {
            return try ModelContainer(for: Task.self, Project.self)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}

