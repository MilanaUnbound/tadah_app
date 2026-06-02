import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.screenContentWidth) private var screenContentWidth
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo
    @Environment(CategoryPickerController.self) private var categoryPicker

    let streakCount: Int

    @State private var selectedDateKey: String
    @Query private var tasks: [Task]
    @Query(sort: [SortDescriptor(\Task.title)]) private var allTasks: [Task]
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var isAddExpanded: Bool = false
    @State private var isConfettiVisible: Bool = false
    @State private var showRecurrenceFailureAlert: Bool = false

    init(streakCount: Int, selectedDateKey: String = DateHelpers.todayKey()) {
        self.streakCount = streakCount
        _selectedDateKey = State(initialValue: selectedDateKey)

        _tasks = Query(
            filter: #Predicate<Task> { task in
                task.dateKey == selectedDateKey
            },
            sort: [SortDescriptor(\Task.title)]
        )
    }

    private var doneCount: Int { tasks.filter(\.isCompleted).count }
    private var isAllDone: Bool { tasks.isEmpty == false && doneCount == tasks.count }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today")
                            .font(.spaceGrotesk(.bold, size: ScreenLayout.headingFontSize(for: screenContentWidth)))

                        Text(DateHelpers.todaySubtitle())
                            .font(.spaceGrotesk(.medium, size: 12))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    StreakBadge(streakCount: streakCount)
                }

                if tasks.isEmpty == false {
                    ProgressBar(doneCount: doneCount, totalCount: tasks.count)
                }

                VStack(spacing: 12) {
                    ForEach(tasks) { task in
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
                            Text(isAllDone ? "Bonus task" : "Add task")
                                .font(.spaceGrotesk(.semibold, size: 14))
                            Spacer()
                        }
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                if isAllDone {
                    AllDoneCard(completedCount: tasks.count)
                        .transition(.opacity.combined(with: .offset(y: 12)))
                        .animation(.easeOut(duration: 0.2).delay(0.12), value: isAllDone)

                    if [3, 7, 14, 30].contains(streakCount) {
                        MilestoneCard(streakCount: streakCount)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            .animation(.spring(response: 0.35, dampingFraction: 0.68).delay(0.3), value: streakCount)
                    }
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
        .onChange(of: isAllDone) { _, allDone in
            guard allDone else { return }
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

    private func addTask(
        title: String,
        categorySelection: CategorySelection,
        scheduledDate: Date,
        recurrence: RecurrenceFormInput
    ) {
        let outcome = TaskInsertHelper.insert(
            title: title,
            categorySelection: categorySelection,
            isBonus: isAllDone,
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
    TodayView(streakCount: 0)
}

