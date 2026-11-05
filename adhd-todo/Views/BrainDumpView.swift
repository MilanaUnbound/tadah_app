import SwiftUI
import SwiftData

struct BrainDumpView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.screenContentWidth) private var screenContentWidth
    @Environment(\.appTheme) private var theme
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo
    @Environment(RescheduleController.self) private var rescheduleController

    @Query(sort: [SortDescriptor(\Task.sortOrder), SortDescriptor(\Task.title)])
    private var allTasks: [Task]

    @Query(sort: \Project.name) private var projects: [Project]

    @State private var newText = ""
    @State private var actionItemID: UUID?
    @State private var showTagPicker = false
    @FocusState private var isInputFocused: Bool

    private var dumpItems: [Task] {
        allTasks.filter { $0.isDump && $0.isCompleted == false }
    }

    var body: some View {
        contentWithOverlay
            .onChange(of: rescheduleController.taskID) { _, newValue in
                handleRescheduleDismiss(newValue)
            }
    }

    private var contentWithOverlay: some View {
        ZStack(alignment: .bottom) {
            mainContent

            if let item = actionItem {
                sheet(for: item)
            }
        }
    }

    private var actionItem: Task? {
        guard let actionItemID else { return nil }
        return dumpItems.first(where: { $0.id == actionItemID })
    }

    private var mainContent: some View {
        AppScrollView(fillsAvailableHeight: true) {
            VStack(alignment: .leading, spacing: 20) {
                titleLabel
                quickAdd
                listOrEmpty
            }
            .tabContentVerticalPadding()
        }
    }

    private var titleLabel: some View {
        Text("Brain dump")
            .font(.spaceGrotesk(.bold, size: ScreenLayout.headingFontSize(for: screenContentWidth)))
            .foregroundStyle(theme.text)
    }

    private var quickAdd: some View {
        HStack(spacing: 8) {
            TextField("What's on your mind?", text: $newText)
                .font(.spaceGrotesk(.medium, size: 15))
                .foregroundStyle(theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 1)
                .focused($isInputFocused)
                .submitLabel(.done)
                .onSubmit { addItem() }

            addButton
        }
    }

    private var addButton: some View {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        let enabled = trimmed.isEmpty == false
        return Button(action: addItem) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(enabled ? Color.white : theme.textFaint)
                .frame(width: 46, height: 46)
                .background(
                    enabled ? AppTheme.violet : theme.card,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(enabled == false)
    }

    @ViewBuilder
    private var listOrEmpty: some View {
        if dumpItems.isEmpty {
            Text("No dates, no pressure.\nJust dump it here.")
                .font(.spaceGrotesk(.medium, size: 15))
                .foregroundStyle(theme.textFaint)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else {
            VStack(spacing: 8) {
                ForEach(dumpItems, id: \.id) { item in
                    BrainDumpCard(task: item, projects: projects) {
                        actionItemID = item.id
                        showTagPicker = false
                    }
                }
            }
        }
    }

    private func sheet(for item: Task) -> some View {
        BrainDumpActionSheet(
            title: item.title,
            categoryRaw: item.categoryRaw,
            categoryName: TaskCategoryDisplay.displayName(for: item, projects: projects),
            categoryColor: TaskCategoryDisplay.displayColor(for: item, projects: projects),
            scheduleHint: scheduleHint(for: item),
            projects: projects,
            showTagPicker: $showTagPicker,
            onSchedule: { schedule(item.id) },
            onSelectCategory: { selectCategory($0, itemID: item.id) },
            onClearCategory: { clearCategory(item.id) },
            onMarkDone: { completeDumpItem(item.id) },
            onDelete: { deleteDumpItem(item.id) },
            onClose: { dismissActionSheet() }
        )
        .zIndex(1)
    }

    private func scheduleHint(for task: Task) -> String {
        guard let scheduled = task.scheduledDate else {
            return "Pick a date to move it to Today"
        }
        return DateHelpers.longMonthDay(for: scheduled)
    }

    private func handleRescheduleDismiss(_ newValue: UUID?) {
        guard newValue == nil, let id = actionItemID else { return }
        if dumpItems.contains(where: { $0.id == id }) == false {
            dismissActionSheet()
        }
    }

    private func schedule(_ itemID: UUID) {
        showTagPicker = false
        guard let current = dumpItems.first(where: { $0.id == itemID }) else { return }
        rescheduleController.present(task: current)
    }

    private func selectCategory(_ selection: CategorySelection, itemID: UUID) {
        guard let current = dumpItems.first(where: { $0.id == itemID }) else { return }
        selection.apply(to: current)
    }

    private func clearCategory(_ itemID: UUID) {
        guard let current = dumpItems.first(where: { $0.id == itemID }) else { return }
        current.categoryRaw = ""
        current.projectNameSnapshot = nil
        current.projectColorHexSnapshot = nil
    }

    private func addItem() {
        let title = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.isEmpty == false else { return }

        let task = Task(
            title: title,
            category: .other,
            dateKey: DateHelpers.todayKey(),
            isDump: true,
            scheduledDate: nil
        )
        task.categoryRaw = ""
        task.scheduledDate = nil
        modelContext.insert(task)

        newText = ""
        isInputFocused = true
    }

    private func completeDumpItem(_ itemID: UUID) {
        guard let task = dumpItems.first(where: { $0.id == itemID }) else { return }
        let todayKey = DateHelpers.todayKey()
        task.isDump = false
        task.dateKey = todayKey
        task.scheduledDate = DateHelpers.startOfDay(forKey: todayKey)
            ?? Calendar.current.startOfDay(for: Date())
        if task.categoryRaw.isEmpty {
            task.categoryRaw = Category.other.rawValue
        }
        TaskCompletionHelper.setCompleted(task, completed: true)
        dismissActionSheet()
    }

    private func deleteDumpItem(_ itemID: UUID) {
        guard let task = dumpItems.first(where: { $0.id == itemID }) else { return }
        withAnimation(.easeOut(duration: 0.15)) {
            taskDeleteUndo.delete(task, in: modelContext)
        }
        dismissActionSheet()
    }

    private func dismissActionSheet() {
        BottomSheetDragDismissState.dismissWithoutAnimation {
            actionItemID = nil
            showTagPicker = false
        }
    }
}

private struct BrainDumpCard: View {
    @Environment(\.appTheme) private var theme

    let task: Task
    let projects: [Project]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                dumpGrip

                VStack(alignment: .leading, spacing: 5) {
                    Text(task.title)
                        .font(.spaceGrotesk(.medium, size: 15))
                        .foregroundStyle(theme.text)
                        .lineLimit(1)

                    meta
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var dumpGrip: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Circle().fill(theme.textSub).frame(width: 3, height: 3)
                Circle().fill(theme.textSub).frame(width: 3, height: 3)
            }
            HStack(spacing: 3) {
                Circle().fill(theme.textSub).frame(width: 3, height: 3)
                Circle().fill(theme.textSub).frame(width: 3, height: 3)
            }
            HStack(spacing: 3) {
                Circle().fill(theme.textSub).frame(width: 3, height: 3)
                Circle().fill(theme.textSub).frame(width: 3, height: 3)
            }
        }
        .opacity(0.3)
    }

    @ViewBuilder
    private var meta: some View {
        let hasCategory = task.categoryRaw.isEmpty == false
        if task.scheduledDate != nil || hasCategory {
            HStack(spacing: 6) {
                if let scheduled = task.scheduledDate {
                    Label(DateHelpers.shortMonthDay(for: scheduled), systemImage: "calendar")
                        .font(.spaceGrotesk(.medium, size: 11))
                        .foregroundStyle(theme.textMuted)
                        .labelStyle(.titleAndIcon)
                }

                if hasCategory {
                    Text(TaskCategoryDisplay.displayName(for: task, projects: projects))
                        .font(.spaceGrotesk(.medium, size: 11))
                        .foregroundStyle(TaskCategoryDisplay.displayColor(for: task, projects: projects))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 1)
                        .background(
                            TaskCategoryDisplay.displayColor(for: task, projects: projects).opacity(0.13),
                            in: Capsule()
                        )
                }
            }
        }
    }
}
