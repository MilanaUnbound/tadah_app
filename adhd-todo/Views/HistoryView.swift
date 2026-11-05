import SwiftUI
import SwiftData

struct RecurringInstancePickerContext: Identifiable {
    let id: UUID
    let title: String
    let instances: [Task]
}

private enum HistoryDrillDownScope: Equatable {
    case allTime
    case month(year: Int, month: Int)
    case year(year: Int)
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.screenContentWidth) private var screenContentWidth
    @Environment(\.appTheme) private var theme
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo
    @Environment(CategoryPickerController.self) private var categoryPicker
    @Environment(RescheduleController.self) private var rescheduleController

    @Query private var allTasks: [Task]
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var period: HistoryPeriod = .month
    @State private var viewYear: Int
    @State private var viewMonth: Int
    @State private var search = ""
    @State private var drillDownCategoryRaw: String?
    @State private var drillDownScope: HistoryDrillDownScope = .allTime
    @State private var recurringInstancePicker: RecurringInstancePickerContext?

    init() {
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

    private var periodSummaries: [HistoryProjectSummary] {
        HistoryBrowseHelper.periodProjectSummaries(
            from: allTasks,
            projects: projects,
            period: period,
            viewYear: viewYear,
            viewMonth: viewMonth,
            search: search
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

        switch drillDownScope {
        case .allTime:
            return HistoryBrowseHelper.tasks(forCategoryRaw: key, from: allTasks)
        case .month(let year, let month):
            let inPeriod = HistoryBrowseHelper.tasksInPeriod(
                from: allTasks,
                period: .month,
                viewYear: year,
                viewMonth: month
            )
            return HistoryBrowseHelper.tasks(forCategoryRaw: key, from: inPeriod)
        case .year(let year):
            let inPeriod = HistoryBrowseHelper.tasksInPeriod(
                from: allTasks,
                period: .year,
                viewYear: year,
                viewMonth: viewMonth
            )
            return HistoryBrowseHelper.tasks(forCategoryRaw: key, from: inPeriod)
        }
    }

    private var drillDownTitle: String {
        guard drillDownCategoryRaw != nil,
              let sample = drillDownTasks.first else { return "" }
        return TaskCategoryDisplay.displayName(for: sample, projects: projects)
    }

    private var upcomingTasks: [Task] {
        let todayKey = DateHelpers.todayKey()
        return allTasks
            .filter { $0.isDump == false && $0.dateKey > todayKey }
            .sorted { lhs, rhs in
                lhs.resolvedScheduledDate < rhs.resolvedScheduledDate
            }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppScrollView(fillsAvailableHeight: true) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Log")
                        .font(.spaceGrotesk(.bold, size: ScreenLayout.headingFontSize(for: screenContentWidth)))
                        .foregroundStyle(theme.text)

                    if upcomingTasks.isEmpty == false {
                        UpcomingSection(
                            tasks: upcomingTasks,
                            projects: projects,
                            onScheduleTap: { task in
                                rescheduleController.present(task: task)
                            },
                            onDelete: { task in
                                withAnimation(.easeOut(duration: 0.15)) {
                                    if task.recurrenceSeriesId != nil {
                                        taskDeleteUndo.deleteUpcoming(
                                            for: task,
                                            from: allTasks,
                                            in: modelContext
                                        )
                                    } else {
                                        taskDeleteUndo.delete(task, in: modelContext)
                                    }
                                }
                            },
                            onRecurringSwipeRight: { instances in
                                guard let first = instances.first else { return }
                                recurringInstancePicker = RecurringInstancePickerContext(
                                    id: first.recurrenceSeriesId ?? first.id,
                                    title: first.title,
                                    instances: instances
                                )
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

            if let picker = recurringInstancePicker {
                RecurringInstancePickerSheet(
                    title: picker.title,
                    instances: picker.instances,
                    onComplete: { task in
                        withAnimation(.easeOut(duration: 0.15)) {
                            TaskCompletionHelper.setCompleted(task, completed: true)
                        }
                        dismissRecurringInstancePicker()
                    },
                    onDelete: { task in
                        withAnimation(.easeOut(duration: 0.15)) {
                            taskDeleteUndo.delete(task, in: modelContext)
                        }
                        dismissRecurringInstancePicker()
                    },
                    onCancel: {
                        dismissRecurringInstancePicker()
                    }
                )
                .transition(.opacity)
            }
        }
    }

    private func dismissRecurringInstancePicker() {
        BottomSheetDragDismissState.dismissWithoutAnimation {
            recurringInstancePicker = nil
        }
    }

    @ViewBuilder
    private var browseContent: some View {
        HistoryPeriodControl(
            period: $period,
            periodLabel: navigatorPeriodLabel,
            navigatorWidth: StreakBadgeLayout.navigatorMinWidth,
            showsNavigation: period != .project,
            onPeriodChange: {
                search = ""
                drillDownCategoryRaw = nil
                drillDownScope = .allTime
            },
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
        HistoryProjectSearchBar(text: $search)

        if periodSummaries.isEmpty {
            Text("No tasks in this period.")
                .font(.spaceGrotesk(.medium, size: 15))
                .foregroundStyle(theme.textFaint)
        } else {
            VStack(spacing: 12) {
                ForEach(periodSummaries) { summary in
                    HistoryProjectRow(summary: summary) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            drillDownScope = period == .month
                                ? .month(year: viewYear, month: viewMonth)
                                : .year(year: viewYear)
                            drillDownCategoryRaw = summary.categoryRaw
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
                .foregroundStyle(theme.textFaint)
        } else {
            VStack(spacing: 12) {
                ForEach(projectSummaries) { summary in
                    HistoryProjectRow(summary: summary) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            drillDownScope = .allTime
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
                drillDownScope = .allTime
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text(drillDownTitle)
                    .font(.spaceGrotesk(.semibold, size: 16))
            }
            .foregroundStyle(theme.textSub)
        }
        .buttonStyle(.plain)

        if let categoryRaw = drillDownCategoryRaw {
            Button {
                categoryPicker.presentBulk(sourceCategoryRaw: categoryRaw)
            } label: {
                Text("Reassign all tasks")
                    .font(.spaceGrotesk(.medium, size: 13))
                    .foregroundStyle(theme.textFaint)
                    .underline(true, color: theme.textFaint)
            }
            .buttonStyle(.plain)
        }

        if drillDownTasks.isEmpty {
            Text("Nothing here.")
                .font(.spaceGrotesk(.medium, size: 15))
                .foregroundStyle(theme.textFaint)
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
                                onRowTap: {
                                    rescheduleController.present(task: task)
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
    HistoryView()
}
