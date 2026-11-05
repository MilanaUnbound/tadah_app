import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.appTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .today
    @State private var taskDeleteUndo = TaskDeleteUndoController()
    @State private var categoryPicker = CategoryPickerController()
    @State private var rescheduleController = RescheduleController()
    @Query(sort: [SortDescriptor(\Task.dateKey), SortDescriptor(\Task.title)]) private var allTasks: [Task]
    @Query(sort: \Project.name) private var projects: [Project]
    @State private var isShowingSettings: Bool = false
    @Environment(\.modelContext) private var modelContext
    
    init() {}
    
    var body: some View {
        GeometryReader { geo in
            let contentWidth = geo.size.width
            let sidePad = ScreenLayout.sidePadding(for: contentWidth)

            ZStack(alignment: .bottom) {
                theme.bg
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        TabPillBar(selectedTab: $selectedTab)
                            .frame(maxWidth: .infinity)

                        SettingsGearButton(onTap: { isShowingSettings = true })
                    }

                    Group {
                        switch selectedTab {
                        case .today:
                            TodayView()
                        case .history:
                            HistoryView()
                        case .brain:
                            BrainDumpView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, sidePad)
                .padding(.vertical, 16)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)

                UndoDeleteSnackBar()
                    .padding(.bottom, 36)
                    .animation(.easeOut(duration: 0.25), value: taskDeleteUndo.pendingUndo != nil)

                if let context = categoryPicker.context {
                    CategoryPickerSheet(
                        projects: projects,
                        context: context,
                        onSelect: { selection in
                            categoryPicker.apply(selection, tasks: allTasks)
                        },
                        onClose: {
                            BottomSheetDragDismissState.dismissWithoutAnimation {
                                categoryPicker.dismiss()
                            }
                        }
                    )
                    .zIndex(1)
                }

                if let taskID = rescheduleController.taskID,
                   let task = allTasks.first(where: { $0.id == taskID }) {
                    let seriesTasks = RecurrenceSeriesHelper.seriesTasks(for: task, from: allTasks)
                    RescheduleSheet(
                        task: task,
                        seriesTasks: seriesTasks,
                        onConfirm: { result in
                            rescheduleController.apply(
                                result: result,
                                task: task,
                                allTasks: allTasks,
                                projects: projects,
                                in: modelContext
                            )
                        },
                        onCancel: {
                            BottomSheetDragDismissState.dismissWithoutAnimation {
                                rescheduleController.dismiss()
                            }
                        }
                    )
                    .zIndex(1)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .environment(\.screenContentWidth, contentWidth)
        }
        .environment(taskDeleteUndo)
        .environment(categoryPicker)
        .environment(rescheduleController)
        .sheet(isPresented: $isShowingSettings) {
            SettingsSheetView()
                .environment(taskDeleteUndo)
                .environment(preferences)
                .withAppTheme()
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
        .task {
            let todayKey = DateHelpers.todayKey()
            let lastKey = LastOpenedStore.getLastOpenedKey()

            if lastKey == nil {
                LastOpenedStore.setLastOpenedKey(todayKey)
            } else if lastKey != todayKey {
                LastOpenedStore.setLastOpenedKey(todayKey)
            }

            runAutoBackup(force: false)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                runAutoBackup(force: true)
            }
        }
        .withAppTheme()
    }

    private func runAutoBackup(force: Bool) {
        LocalAutoBackupHelper.backupIfNeeded(
            tasks: allTasks,
            projects: projects,
            force: force
        )
    }
}

private struct SettingsGearButton: View {
    let onTap: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "gearshape")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(theme.textSub)
                .frame(width: 36, height: 36)
                .background(theme.tabBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environment(AppPreferences())
}
