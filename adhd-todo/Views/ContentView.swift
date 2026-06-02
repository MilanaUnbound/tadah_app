import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: AppTab = .today
    @State private var taskDeleteUndo = TaskDeleteUndoController()
    @State private var categoryPicker = CategoryPickerController()
    @Query(sort: [SortDescriptor(\Task.dateKey), SortDescriptor(\Task.title)]) private var allTasks: [Task]
    @Query(sort: \Project.name) private var projects: [Project]

    private var streakCount: Int {
        var byDate: [String: [Task]] = [:]
        byDate.reserveCapacity(64)

        for t in allTasks {
            byDate[t.dateKey, default: []].append(t)
        }

        return StreakCalculator.calculate(todayKey: DateHelpers.todayKey(), tasksByDateKey: byDate)
    }

    var body: some View {
        GeometryReader { geo in
            let contentWidth = geo.size.width
            let sidePad = ScreenLayout.sidePadding(for: contentWidth)

            ZStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 16) {
                    TabPillBar(selectedTab: $selectedTab)

                    Group {
                        switch selectedTab {
                        case .today:
                            TodayView(streakCount: streakCount)
                        case .history:
                            HistoryView(streakCount: streakCount)
                        case .recap:
                            RecapView(streakCount: streakCount)
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
                            categoryPicker.dismiss()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .environment(\.screenContentWidth, contentWidth)
            .environment(taskDeleteUndo)
            .environment(categoryPicker)
            .animation(.easeOut(duration: 0.2), value: categoryPicker.context?.id)
        }
        .task {
            let todayKey = DateHelpers.todayKey()
            let lastKey = LastOpenedStore.getLastOpenedKey()

            if lastKey == nil {
                LastOpenedStore.setLastOpenedKey(todayKey)
            } else if lastKey != todayKey {
                LastOpenedStore.setLastOpenedKey(todayKey)
            }
        }
    }
}

#Preview {
    ContentView()
}
