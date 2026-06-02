import Foundation
import Testing
@testable import ADHD_Figma

struct TaskCategoryKeyTests {
    @Test func projectRawValue_roundTripsUUID() {
        let id = UUID()
        let raw = TaskCategoryKey.rawValue(projectId: id)
        #expect(raw.hasPrefix(TaskCategoryKey.projectPrefix))
        #expect(TaskCategoryKey.projectId(from: raw) == id)
    }

    @Test func isBuiltin_recognizesCategoryRaw() {
        #expect(TaskCategoryKey.isBuiltin("work"))
        #expect(TaskCategoryKey.isBuiltin("health"))
        #expect(TaskCategoryKey.isBuiltin("project:\(UUID())") == false)
    }

    @Test func displayName_usesSnapshotWhenProjectMissing() {
        let id = UUID()
        let task = Task(
            title: "T",
            category: .other,
            dateKey: "2026-05-01",
            projectNameSnapshot: "Side hustle",
            projectColorHexSnapshot: "#7B2FFF"
        )
        task.categoryRaw = TaskCategoryKey.rawValue(projectId: id)

        let name = TaskCategoryDisplay.displayName(for: task, projects: [])
        #expect(name == "Side hustle")
    }

    @Test func breakdownInfo_usesSnapshotForDeletedProject() {
        let id = UUID()
        let task = Task(
            title: "T",
            category: .other,
            dateKey: "2026-05-01",
            projectNameSnapshot: "Side hustle",
            projectColorHexSnapshot: "#22C55E"
        )
        let raw = TaskCategoryKey.rawValue(projectId: id)
        task.categoryRaw = raw

        let info = TaskCategoryDisplay.breakdownInfo(
            forGroupKey: raw,
            sampleTask: task,
            projects: []
        )
        #expect(info.displayName == "Side hustle")
        #expect(info.colorHex == "#22C55E")
    }
}
