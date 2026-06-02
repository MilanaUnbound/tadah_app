import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: AppTab = .today
    @State private var taskDeleteUndo = TaskDeleteUndoController()
    @State private var categoryPicker = CategoryPickerController()
    @Query(sort: [SortDescriptor(\Task.dateKey), SortDescriptor(\Task.title)]) private var allTasks: [Task]
    @Query(sort: \Project.name) private var projects: [Project]
    @State private var streakCount: Int = 0
    @State private var isShowingSettings: Bool = false
    
    init() {}
    
    private struct StreakSignature: Equatable {
        let id: UUID
        let dateKey: String
        let isBonus: Bool
        let isCompleted: Bool
    }

    private var streakSignature: [StreakSignature] {
        allTasks.map { StreakSignature(id: $0.id, dateKey: $0.dateKey, isBonus: $0.isBonus, isCompleted: $0.isCompleted) }
    }

    var body: some View {
        GeometryReader { geo in
            let contentWidth = geo.size.width
            let sidePad = ScreenLayout.sidePadding(for: contentWidth)

            ZStack(alignment: .bottom) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        TabPillBar(selectedTab: $selectedTab)
                            .frame(maxWidth: .infinity)

                        SettingsPillButton(
                            onTap: { isShowingSettings = true },
                            isActive: isShowingSettings
                        )
                    }

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
        .sheet(isPresented: $isShowingSettings) {
            SettingsSheetView()
        }
        .task {
            let todayKey = DateHelpers.todayKey()
            let lastKey = LastOpenedStore.getLastOpenedKey()

            if lastKey == nil {
                LastOpenedStore.setLastOpenedKey(todayKey)
            } else if lastKey != todayKey {
                LastOpenedStore.setLastOpenedKey(todayKey)
            }

            recomputeStreak(now: Date())
        }
        .onChange(of: streakSignature) { _, _ in
            recomputeStreak(now: Date())
        }
    }

    private func recomputeStreak(now: Date) {
        // Derived value: keep out of `body` so first frame renders ASAP.
        var byDate: [String: [Task]] = [:]
        byDate.reserveCapacity(64)
        for t in allTasks {
            byDate[t.dateKey, default: []].append(t)
        }
        streakCount = StreakCalculator.calculate(
            todayKey: DateHelpers.todayKey(now: now),
            tasksByDateKey: byDate,
            now: now
        )
    }
}

private struct SettingsPillButton: View {
    let onTap: () -> Void
    let isActive: Bool

    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)
    private let tabBarBg = Color(.systemGray5)
    private let inactiveText = Color(.secondaryLabel)

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "gearshape")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? violet : inactiveText)
                .frame(height: 38)
                .frame(width: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isActive ? Color.white : Color.clear)
                )
                .shadow(
                    color: Color.black.opacity(isActive ? 0.08 : 0),
                    radius: isActive ? 8 : 0,
                    x: 0,
                    y: isActive ? 2 : 0
                )
        }
        .buttonStyle(.plain)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tabBarBg)
        )
    }
}

#Preview {
    ContentView()
}
