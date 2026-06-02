import Foundation
import Testing
@testable import ADHD_Figma

struct HistoryBrowseHelperTests {
    @Test func completedTasks_filtersByMonth() {
        let task = Task(
            title: "Done",
            category: .work,
            dateKey: "2026-03-10",
            isCompleted: true,
            completedAt: date(year: 2026, month: 3, day: 15)
        )
        let other = Task(
            title: "Other",
            category: .work,
            dateKey: "2026-04-01",
            isCompleted: true,
            completedAt: date(year: 2026, month: 4, day: 1)
        )

        let march = HistoryBrowseHelper.completedTasks(
            from: [task, other],
            period: .month,
            viewYear: 2026,
            viewMonth: 3
        )

        #expect(march.count == 1)
        #expect(march[0].title == "Done")
    }

    @Test func legacyCompleted_usesDateKeyFallback() {
        let task = Task(
            title: "Legacy",
            category: .home,
            dateKey: "2025-12-20",
            isCompleted: true
        )
        #expect(task.completedAt == nil)

        let filtered = HistoryBrowseHelper.completedTasks(
            from: [task],
            period: .year,
            viewYear: 2025,
            viewMonth: 12
        )

        #expect(filtered.count == 1)
    }

    @Test func groupedCompletedTasks_sortsNewestFirst() {
        let older = Task(
            title: "Older",
            category: .work,
            dateKey: "2026-01-01",
            isCompleted: true,
            completedAt: date(year: 2026, month: 1, day: 5)
        )
        let newer = Task(
            title: "Newer",
            category: .work,
            dateKey: "2026-01-02",
            isCompleted: true,
            completedAt: date(year: 2026, month: 1, day: 20)
        )

        let groups = HistoryBrowseHelper.groupedCompletedTasks(
            from: [older, newer],
            period: .month,
            viewYear: 2026,
            viewMonth: 1
        )

        #expect(groups.count == 2)
        #expect(groups[0].tasks[0].title == "Newer")
    }

    @Test func projectSummaries_countsDoneAndTotal() {
        let done = Task(title: "A", category: .work, dateKey: "2026-05-01", isCompleted: true)
        let open = Task(title: "B", category: .work, dateKey: "2026-05-02")

        let summaries = HistoryBrowseHelper.projectSummaries(
            from: [done, open],
            projects: [],
            search: ""
        )

        #expect(summaries.count == 1)
        #expect(summaries[0].doneCount == 1)
        #expect(summaries[0].totalCount == 2)
        #expect(summaries[0].percent == 50)
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return Calendar.current.date(from: comps)!
    }
}
