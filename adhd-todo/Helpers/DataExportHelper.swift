import Foundation

struct ExportBundle: Codable {
    let version: Int
    let exportedAt: Date
    let categories: [BuiltinCategoryExport]
    let projects: [ProjectExport]
    let todos: [TodoExport]

    static func make(tasks: [Task], projects: [Project]) -> ExportBundle {
        let categories = Category.allCases.map {
            BuiltinCategoryExport(id: $0.rawValue, displayName: $0.displayName)
        }

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
                isDump: t.isDump,
                sortOrder: t.sortOrder,
                completedAt: t.completedAt,
                scheduledDate: t.scheduledDate,
                recurrenceRuleRaw: t.recurrenceRuleRaw,
                recurrenceSeriesId: t.recurrenceSeriesId,
                customWeekdaysMask: t.customWeekdaysMask,
                categoryRaw: t.categoryRaw,
                categoryRef: CategoryRef.from(categoryRaw: t.categoryRaw),
                projectNameSnapshot: t.projectNameSnapshot,
                projectColorHexSnapshot: t.projectColorHexSnapshot
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

struct BuiltinCategoryExport: Codable {
    let id: String
    let displayName: String
}

struct ProjectExport: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let createdAt: Date
}

struct TodoExport: Codable {
    let id: UUID
    let title: String
    let dateKey: String
    let isCompleted: Bool
    let isBonus: Bool
    let isDump: Bool
    let sortOrder: Int?
    let completedAt: Date?
    let scheduledDate: Date?
    let recurrenceRuleRaw: String?
    let recurrenceSeriesId: UUID?
    let customWeekdaysMask: Int?
    let categoryRaw: String
    let categoryRef: CategoryRef
    let projectNameSnapshot: String?
    let projectColorHexSnapshot: String?

    init(
        id: UUID,
        title: String,
        dateKey: String,
        isCompleted: Bool,
        isBonus: Bool,
        isDump: Bool = false,
        sortOrder: Int? = nil,
        completedAt: Date?,
        scheduledDate: Date?,
        recurrenceRuleRaw: String?,
        recurrenceSeriesId: UUID?,
        customWeekdaysMask: Int?,
        categoryRaw: String,
        categoryRef: CategoryRef,
        projectNameSnapshot: String? = nil,
        projectColorHexSnapshot: String? = nil
    ) {
        self.id = id
        self.title = title
        self.dateKey = dateKey
        self.isCompleted = isCompleted
        self.isBonus = isBonus
        self.isDump = isDump
        self.sortOrder = sortOrder
        self.completedAt = completedAt
        self.scheduledDate = scheduledDate
        self.recurrenceRuleRaw = recurrenceRuleRaw
        self.recurrenceSeriesId = recurrenceSeriesId
        self.customWeekdaysMask = customWeekdaysMask
        self.categoryRaw = categoryRaw
        self.categoryRef = categoryRef
        self.projectNameSnapshot = projectNameSnapshot
        self.projectColorHexSnapshot = projectColorHexSnapshot
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        dateKey = try container.decode(String.self, forKey: .dateKey)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        isBonus = try container.decodeIfPresent(Bool.self, forKey: .isBonus) ?? false
        isDump = try container.decodeIfPresent(Bool.self, forKey: .isDump) ?? false
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        scheduledDate = try container.decodeIfPresent(Date.self, forKey: .scheduledDate)
        recurrenceRuleRaw = try container.decodeIfPresent(String.self, forKey: .recurrenceRuleRaw)
        recurrenceSeriesId = try container.decodeIfPresent(UUID.self, forKey: .recurrenceSeriesId)
        customWeekdaysMask = try container.decodeIfPresent(Int.self, forKey: .customWeekdaysMask)
        categoryRaw = try container.decode(String.self, forKey: .categoryRaw)
        categoryRef = try container.decodeIfPresent(CategoryRef.self, forKey: .categoryRef)
            ?? CategoryRef.from(categoryRaw: categoryRaw)
        projectNameSnapshot = try container.decodeIfPresent(String.self, forKey: .projectNameSnapshot)
        projectColorHexSnapshot = try container.decodeIfPresent(String.self, forKey: .projectColorHexSnapshot)
    }
}

struct CategoryRef: Codable {
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

enum DataExportHelper {
    static func exportData(tasks: [Task], projects: [Project]) throws -> URL {
        let bundle = ExportBundle.make(tasks: tasks, projects: projects)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(bundle)

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let datePart = formatter.string(from: Date())

        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("tasks-backup-\(datePart).json")
        try data.write(to: url, options: [.atomic])
        return url
    }
}
