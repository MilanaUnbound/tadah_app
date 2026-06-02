import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.screenContentWidth) private var screenContentWidth
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo
    @Environment(CategoryPickerController.self) private var categoryPicker

    let streakCount: Int

    @Query private var allTasks: [Task]
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var period: HistoryPeriod = .month
    @State private var viewYear: Int
    @State private var viewMonth: Int
    @State private var search = ""
    @State private var drillDownCategoryRaw: String?
    @State private var streakWidth: CGFloat = StreakBadgeLayout.defaultWidth

    private let muted = Color(red: 0xCC / 255, green: 0xCC / 255, blue: 0xCC / 255)
    private let sectionLabel = Color(red: 0xAA / 255, green: 0xAA / 255, blue: 0xAA / 255)
    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)

    init(streakCount: Int) {
        self.streakCount = streakCount
        let calendar = Calendar.current
        let now = Date()
        _viewYear = State(initialValue: calendar.component(.year, from: now))
        _viewMonth = State(initialValue: calendar.component(.month, from: now))
        _allTasks = Query(sort: [
            SortDescriptor(\Task.dateKey, order: .reverse),
            SortDescriptor(\Task.title),
        ])
    }

    private var navigatorPeriodLabel: String {
        switch period {
        case .year:
            return String(viewYear)
        case .month:
            return DateHelpers.navigatorMonthAbbreviation(year: viewYear, month: viewMonth)
        case .project:
            return ""
        }
    }

    private var groupedCompleted: [(label: String, tasks: [Task])] {
        HistoryBrowseHelper.groupedCompletedTasks(
            from: allTasks,
            period: period,
            viewYear: viewYear,
            viewMonth: viewMonth
        )
    }

    private var projectSummaries: [HistoryProjectSummary] {
        HistoryBrowseHelper.projectSummaries(
            from: allTasks,
            projects: projects,
            search: search
        )
    }

    private var drillDownTasks: [Task] {
        guard let key = drillDownCategoryRaw else { return [] }
        return HistoryBrowseHelper.tasks(forCategoryRaw: key, from: allTasks)
    }

    private var drillDownTitle: String {
        guard let key = drillDownCategoryRaw,
              let sample = drillDownTasks.first else { return "" }
        return TaskCategoryDisplay.displayName(for: sample, projects: projects)
    }

    private var upcomingTasks: [Task] {
        let todayKey = DateHelpers.todayKey()
        return allTasks
            .filter { $0.isCompleted == false }
            .filter { $0.dateKey > todayKey }
            .sorted { lhs, rhs in
                lhs.resolvedScheduledDate < rhs.resolvedScheduledDate
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center) {
                    Text("Log")
                        .font(.spaceGrotesk(.bold, size: ScreenLayout.headingFontSize(for: screenContentWidth)))

                    Spacer()

                    StreakBadge(streakCount: streakCount)
                        .streakWidthReporter()
                }

                if upcomingTasks.isEmpty == false {
                    UpcomingSection(
                        tasks: upcomingTasks,
                        projects: projects,
                        onReschedule: { task, newDate in
                            let cal = Calendar.current
                            let start = cal.startOfDay(for: newDate)
                            withAnimation(.easeOut(duration: 0.15)) {
                                task.dateKey = DateHelpers.dateKey(for: start)
                                task.scheduledDate = start
                            }
                        },
                        onDelete: { task in
                            withAnimation(.easeOut(duration: 0.15)) {
                                taskDeleteUndo.delete(task, in: modelContext)
                            }
                        }
                    )
                }

                if drillDownCategoryRaw != nil {
                    drillDownContent
                } else {
                    browseContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .tabContentVerticalPadding()
        }
        .onStreakWidth { streakWidth = $0 }
    }

    @ViewBuilder
    private var browseContent: some View {
        HistoryPeriodControl(
            period: $period,
            periodLabel: navigatorPeriodLabel,
            navigatorWidth: streakWidth,
            showsNavigation: period != .project,
            onPeriodChange: { search = "" },
            onPrevious: { stepPeriod(direction: -1) },
            onNext: { stepPeriod(direction: 1) }
        )

        switch period {
        case .month, .year:
            monthYearContent
        case .project:
            projectContent
        }
    }

    @ViewBuilder
    private var monthYearContent: some View {
        if groupedCompleted.isEmpty {
            Text("Nothing completed in this period.")
                .font(.spaceGrotesk(.medium, size: 15))
                .foregroundStyle(muted)
        } else {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(groupedCompleted, id: \.label) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.label.uppercased())
                            .font(.spaceGrotesk(.medium, size: 12))
                            .foregroundStyle(sectionLabel)
                            .tracking(0.8)

                        VStack(spacing: 8) {
                            ForEach(group.tasks) { task in
                                HistoryCompletedTaskRow(
                                    task: task,
                                    projects: projects
                                ) {
                                    categoryPicker.present(task: task)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var projectContent: some View {
        HistoryProjectSearchBar(text: $search)

        if projectSummaries.isEmpty {
            Text("No projects found.")
                .font(.spaceGrotesk(.medium, size: 15))
                .foregroundStyle(muted)
        } else {
            VStack(spacing: 12) {
                ForEach(projectSummaries) { summary in
                    HistoryProjectRow(summary: summary) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            drillDownCategoryRaw = summary.categoryRaw
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var drillDownContent: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                drillDownCategoryRaw = nil
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text(drillDownTitle)
                    .font(.spaceGrotesk(.semibold, size: 16))
            }
            .foregroundStyle(violet)
        }
        .buttonStyle(.plain)

        if let categoryRaw = drillDownCategoryRaw {
            Button {
                categoryPicker.presentBulk(sourceCategoryRaw: categoryRaw)
            } label: {
                Text("Reassign all tasks")
                    .font(.spaceGrotesk(.medium, size: 13))
                    .foregroundStyle(muted)
                    .underline(true, color: muted)
            }
            .buttonStyle(.plain)
        }

        if drillDownTasks.isEmpty {
            Text("Nothing here.")
                .font(.spaceGrotesk(.medium, size: 15))
                .foregroundStyle(muted)
        } else {
            VStack(spacing: 8) {
                ForEach(drillDownTasks) { task in
                    if task.isCompleted {
                        HistoryCompletedTaskRow(
                            task: task,
                            projects: projects
                        ) {
                            categoryPicker.present(task: task)
                        }
                    } else {
                        SwipeableTaskRow(
                            taskID: task.id,
                            categoryColor: TaskCategoryDisplay.displayColor(for: task, projects: projects),
                            isCompleted: task.isCompleted,
                            onToggleComplete: {
                                TaskCompletionHelper.toggle(task)
                            },
                            onDelete: {
                                deleteTask(task)
                            }
                        ) {
                            TaskRow(
                                task: task,
                                onToggleComplete: {
                                    TaskCompletionHelper.toggle(task)
                                },
                                onDeleteUpcoming: {
                                    deleteUpcoming(for: task)
                                },
                                onCategoryTap: {
                                    categoryPicker.present(task: task)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private func stepPeriod(direction: Int) {
        withAnimation(.easeOut(duration: 0.15)) {
            switch period {
            case .month:
                HistoryBrowseHelper.stepMonth(
                    viewYear: &viewYear,
                    viewMonth: &viewMonth,
                    direction: direction
                )
            case .year:
                HistoryBrowseHelper.stepYear(viewYear: &viewYear, direction: direction)
            case .project:
                break
            }
        }
    }

    private func deleteTask(_ task: Task) {
        withAnimation(.easeOut(duration: 0.15)) {
            taskDeleteUndo.delete(task, in: modelContext)
        }
    }

    private func deleteUpcoming(for task: Task) {
        withAnimation(.easeOut(duration: 0.15)) {
            RecurrenceSeriesHelper.deleteUpcoming(
                for: task,
                from: allTasks,
                in: modelContext
            )
        }
    }
}

#Preview {
    HistoryView(streakCount: 7)
}
