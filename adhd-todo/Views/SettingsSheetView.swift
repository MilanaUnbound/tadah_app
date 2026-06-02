import SwiftUI
import SwiftData

struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: [SortDescriptor(\Task.dateKey), SortDescriptor(\Task.title)]) private var tasks: [Task]
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var exportURL: URL?
    @State private var exportErrorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        export()
                    } label: {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }
                } footer: {
                    Text("Exports your todos, projects, and categories as a JSON file you can save anywhere.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Export failed", isPresented: Binding(get: {
                exportErrorMessage != nil
            }, set: { newValue in
                if newValue == false { exportErrorMessage = nil }
            })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportErrorMessage ?? "Unknown error.")
            }
            .sheet(item: Binding(get: {
                exportURL.map(ExportedFile.init(url:))
            }, set: { newValue in
                exportURL = newValue?.url
            })) { exported in
                ActivityView(activityItems: [exported.url])
                    .ignoresSafeArea()
            }
        }
    }

    private func export() {
        do {
            let bundle = ExportBundle.make(tasks: tasks, projects: projects)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(bundle)

            let fileURL = try writeExportFile(data: data)
            exportURL = fileURL
        } catch {
            exportErrorMessage = String(describing: error)
        }
    }

    private func writeExportFile(data: Data) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
        let fileName = "tadah-export-\(timestamp()).json"
        let url = dir.appendingPathComponent(fileName)
        try data.write(to: url, options: [.atomic])
        return url
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
}

private struct ExportedFile: Identifiable {
    let id = UUID()
    let url: URL

    init(url: URL) { self.url = url }
}

private struct ExportBundle: Codable {
    let version: Int
    let exportedAt: Date
    let categories: [BuiltinCategoryExport]
    let projects: [ProjectExport]
    let todos: [TodoExport]

    static func make(tasks: [Task], projects: [Project]) -> ExportBundle {
        let categories = Category.allCases.map { BuiltinCategoryExport(id: $0.rawValue, displayName: $0.displayName) }

        let projectExports = projects.map { p in
            ProjectExport(
                id: p.id,
                name: p.name,
                colorHex: p.colorHex,
                createdAt: p.createdAt
            )
        }

        let todoExports = tasks.map { t in
            TodoExport(
                id: t.id,
                title: t.title,
                dateKey: t.dateKey,
                isCompleted: t.isCompleted,
                isBonus: t.isBonus,
                completedAt: t.completedAt,
                scheduledDate: t.scheduledDate,
                recurrenceRuleRaw: t.recurrenceRuleRaw,
                recurrenceSeriesId: t.recurrenceSeriesId,
                customWeekdaysMask: t.customWeekdaysMask,
                categoryRaw: t.categoryRaw,
                categoryRef: CategoryRef.from(categoryRaw: t.categoryRaw)
            )
        }

        return ExportBundle(
            version: 1,
            exportedAt: Date(),
            categories: categories,
            projects: projectExports,
            todos: todoExports
        )
    }
}

private struct BuiltinCategoryExport: Codable {
    let id: String
    let displayName: String
}

private struct ProjectExport: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let createdAt: Date
}

private struct TodoExport: Codable {
    let id: UUID
    let title: String
    let dateKey: String
    let isCompleted: Bool
    let isBonus: Bool
    let completedAt: Date?
    let scheduledDate: Date?

    let recurrenceRuleRaw: String?
    let recurrenceSeriesId: UUID?
    let customWeekdaysMask: Int?

    let categoryRaw: String
    let categoryRef: CategoryRef
}

private struct CategoryRef: Codable {
    enum RefType: String, Codable {
        case builtin
        case project
        case unknown
    }

    let type: RefType
    let id: String

    static func from(categoryRaw: String) -> CategoryRef {
        if TaskCategoryKey.isBuiltin(categoryRaw) {
            return CategoryRef(type: .builtin, id: categoryRaw)
        }
        if let projectId = TaskCategoryKey.projectId(from: categoryRaw) {
            return CategoryRef(type: .project, id: projectId.uuidString)
        }
        return CategoryRef(type: .unknown, id: categoryRaw)
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

