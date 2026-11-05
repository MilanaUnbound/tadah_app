import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.screenContentWidth) private var screenContentWidth
    @Environment(\.appTheme) private var theme
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo
    @Environment(CategoryPickerController.self) private var categoryPicker
    @Environment(RescheduleController.self) private var rescheduleController

    @State private var selectedDateKey: String
    @Query private var tasks: [Task]
    @Query(sort: [SortDescriptor(\Task.title)]) private var allTasks: [Task]
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var isAddExpanded: Bool = false
    @State private var isConfettiVisible: Bool = false
    @State private var showRecurrenceFailureAlert: Bool = false

    init(selectedDateKey: String = DateHelpers.todayKey()) {
        _selectedDateKey = State(initialValue: selectedDateKey)

        _tasks = Query(
            filter: #Predicate<Task> { task in
                task.dateKey == selectedDateKey && task.isDump == false
            },
            sort: [
                SortDescriptor(\Task.sortOrder),
                SortDescriptor(\Task.title),
            ]
        )
    }

    private var doneCount: Int { tasks.filter(\.isCompleted).count }
    private var normalTasks: [Task] { DayCompletionHelper.normalTasks(from: tasks) }
    private var bonusTasks: [Task] { tasks.filter(\.isBonus) }
    private var normalCompletedCount: Int { normalTasks.filter(\.isCompleted).count }
    private var allNormalTasksComplete: Bool {
        DayCompletionHelper.allNormalTasksComplete(tasks: tasks)
    }

    var body: some View {
        ZStack {
            AppScrollView(fillsAvailableHeight: true) {
                VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today")
                            .font(.spaceGrotesk(.bold, size: ScreenLayout.headingFontSize(for: screenContentWidth)))
                            .foregroundStyle(theme.text)

                        Text(DateHelpers.todaySubtitle())
                            .font(.spaceGrotesk(.medium, size: 12))
                            .foregroundStyle(theme.textSub)
                    }

                    Spacer(minLength: 0)
                }

                if tasks.isEmpty == false {
                    ProgressBar(doneCount: doneCount, totalCount: tasks.count)
                }

                VStack(spacing: 12) {
                    if normalTasks.isEmpty == false {
                        ReorderableTaskList(
                            tasks: normalTasks,
                            onMove: { taskID, toIndex in
                                moveTask(taskID: taskID, toIndex: toIndex, in: normalTasks)
                            }
                        ) { task, dragGesture in
                            todayTaskRow(task: task, reorderDragGesture: dragGesture)
                        }
                    }

                    if bonusTasks.isEmpty == false {
                        ReorderableTaskList(
                            tasks: bonusTasks,
                            onMove: { taskID, toIndex in
                                moveTask(taskID: taskID, toIndex: toIndex, in: bonusTasks)
                            }
                        ) { task, dragGesture in
                            todayTaskRow(task: task, reorderDragGesture: dragGesture)
                        }
                    }
                }

                if isAddExpanded {
                    AddTaskInlineForm(isExpanded: $isAddExpanded) { title, categorySelection, scheduledDate, recurrence in
                        addTask(
                            title: title,
                            categorySelection: categorySelection,
                            scheduledDate: scheduledDate,
                            recurrence: recurrence
                        )
                    }
                } else {
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            isAddExpanded = true
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text(allNormalTasksComplete ? "Bonus task" : "Add task")
                                .font(.spaceGrotesk(.semibold, size: 14))
                            Spacer()
                        }
                        .foregroundStyle(theme.textSub)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(theme.btnBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                if allNormalTasksComplete {
                    AllDoneCard(completedCount: normalCompletedCount)
                        .transition(.opacity.combined(with: .offset(y: 12)))
                        .animation(.easeOut(duration: 0.2).delay(0.12), value: allNormalTasksComplete)
                }
                }
                .tabContentVerticalPadding()
            }

            if isConfettiVisible {
                ConfettiCanvas(onFinished: {
                    isConfettiVisible = false
                })
            }
        }
        .onAppear {
            TaskReorderHelper.normalizeSortOrders(tasks)
        }
        .onChange(of: tasks.count) { _, _ in
            TaskReorderHelper.normalizeSortOrders(tasks)
        }
        .onChange(of: allNormalTasksComplete) { _, metGoal in
            guard metGoal else { return }
            guard tasks.isEmpty == false else { return }
            isConfettiVisible = true
        }
        .alert(
            "Repeat",
            isPresented: $showRecurrenceFailureAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(TaskInsertHelper.recurrenceFailureMessage)
        }
    }

    private func todayTaskRow(
        task: Task,
        reorderDragGesture: AnyGesture<DragGesture.Value>?
    ) -> some View {
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
                checkboxIsInteractive: false,
                showsScheduleSubtitle: true,
                onRowTap: {
                    handleTaskRowTap(task)
                },
                onDeleteUpcoming: {
                    deleteUpcoming(for: task)
                },
                onCategoryTap: {
                    categoryPicker.present(task: task)
                },
                leadingAccessory: .dragHandle,
                reorderDragGesture: reorderDragGesture
            )
        }
    }

    private func moveTask(taskID: UUID, toIndex: Int, in sectionTasks: [Task]) {
        TaskReorderHelper.move(taskID: taskID, toIndex: toIndex, in: sectionTasks)
    }

    private func handleTaskRowTap(_ task: Task) {
        if task.isCompleted {
            TaskCompletionHelper.toggle(task)
        } else {
            rescheduleController.present(task: task)
        }
    }

    private func addTask(
        title: String,
        categorySelection: CategorySelection,
        scheduledDate: Date,
        recurrence: RecurrenceFormInput
    ) {
        let outcome = TaskInsertHelper.insert(
            title: title,
            categorySelection: categorySelection,
            isBonus: allNormalTasksComplete,
            scheduledDate: scheduledDate,
            recurrence: recurrence,
            into: modelContext
        )

        if outcome == .recurrenceFallback {
            showRecurrenceFailureAlert = true
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
    TodayView()
}

