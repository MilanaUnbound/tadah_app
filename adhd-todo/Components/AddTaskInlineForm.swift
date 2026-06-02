import SwiftUI
import SwiftData

struct AddTaskInlineForm: View {
    private enum FocusTarget: Hashable {
        case title
        case newProjectName
    }

    @Binding var isExpanded: Bool

    /// When set (e.g. History on a future day), the schedule field defaults to this day.
    var initialScheduledDate: Date? = nil

    let onSubmit: (
        _ title: String,
        _ categorySelection: CategorySelection,
        _ scheduledDate: Date,
        _ recurrence: RecurrenceFormInput
    ) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var title: String = ""
    @State private var selection: CategorySelection = LastUsedSelectionStore.load() ?? .builtin(.other)
    @State private var scheduledDate: Date = DateHelpers.startOfToday()
    @State private var isSchedulePickerPresented: Bool = false
    @State private var isRepeatEnabled: Bool = false
    @State private var selectedRecurrenceRule: RecurrenceRule = .daily
    @State private var customWeekdays: Set<Int> = []
    @State private var isCreatingProject: Bool = false
    @State private var newProjectName: String = ""
    @FocusState private var focus: FocusTarget?

    private var scheduleRange: ClosedRange<Date> {
        let start = DateHelpers.startOfToday()
        let end = Calendar.current.date(byAdding: .year, value: 2, to: start) ?? start
        return start ... end
    }

    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)
    private let sectionBorder = Color(red: 0xF0 / 255, green: 0xF0 / 255, blue: 0xF0 / 255)

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNewProjectName: String {
        newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        guard trimmedTitle.isEmpty == false else { return false }
        if isRepeatEnabled && selectedRecurrenceRule == .custom && customWeekdays.isEmpty {
            return false
        }
        return true
    }

    private var canCreateProject: Bool {
        trimmedNewProjectName.isEmpty == false
    }

    private var recurrenceInput: RecurrenceFormInput {
        if isRepeatEnabled {
            return RecurrenceFormInput(
                isEnabled: true,
                rule: selectedRecurrenceRule,
                customWeekdays: customWeekdays
            )
        }
        return .disabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("What needs doing?", text: $title)
                .focused($focus, equals: .title)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .onSubmit { submitIfPossible() }
                .contentShape(Rectangle())
                .onTapGesture { focus = .title }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            FlowLayout(spacing: 10, rowSpacing: 10) {
                ForEach(Category.allCases) { cat in
                    CategoryPill(
                        category: cat,
                        isSelected: isBuiltinSelected(cat)
                    ) {
                        selectBuiltin(cat)
                    }
                }
            }

            customProjectsSection

            Button {
                isSchedulePickerPresented = true
            } label: {
                HStack {
                    Text("Scheduled for")
                        .font(.spaceGrotesk(.medium, size: 13))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(DateHelpers.scheduleLabel(for: scheduledDate))
                        .font(.spaceGrotesk(.semibold, size: 13))
                        .foregroundStyle(Color.primary)
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(violet)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isSchedulePickerPresented) {
                NavigationStack {
                    DatePicker(
                        "Scheduled for",
                        selection: $scheduledDate,
                        in: scheduleRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                    .navigationTitle("Scheduled for")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                scheduledDate = clampedScheduleDate(scheduledDate)
                                isSchedulePickerPresented = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }

            Toggle(isOn: $isRepeatEnabled) {
                Text("Repeat")
                    .font(.spaceGrotesk(.medium, size: 13))
                    .foregroundStyle(Color.primary)
            }
            .tint(violet)

            if isRepeatEnabled {
                Picker("Repeat", selection: $selectedRecurrenceRule) {
                    ForEach(RecurrenceRule.repeatableCases) { rule in
                        Text(rule.displayName).tag(rule)
                    }
                }
                .pickerStyle(.segmented)

                if selectedRecurrenceRule == .custom {
                    HStack(spacing: 8) {
                        ForEach(WeekdayPickerOption.mondayFirstOptions) { option in
                            WeekdayTogglePill(
                                label: option.label,
                                isSelected: customWeekdays.contains(option.id)
                            ) {
                                if customWeekdays.contains(option.id) {
                                    customWeekdays.remove(option.id)
                                } else {
                                    customWeekdays.insert(option.id)
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    submitIfPossible()
                } label: {
                    Text("Add task")
                        .font(.spaceGrotesk(.bold, size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.white)
                .background(violet.opacity(canSubmit ? 1 : 0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .disabled(!canSubmit)

                Button {
                    collapse()
                } label: {
                    Text("Cancel")
                        .font(.spaceGrotesk(.semibold, size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.secondary)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(violet, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .transition(.opacity.combined(with: .offset(y: -8)))
        .animation(.easeOut(duration: 0.15), value: isExpanded)
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                scheduledDate = clampedScheduleDate(
                    initialScheduledDate ?? DateHelpers.startOfToday()
                )
                isRepeatEnabled = false
                selectedRecurrenceRule = .daily
                customWeekdays = []
                isCreatingProject = false
                newProjectName = ""
                restoreLastUsedProjectSelection()
            } else {
                focus = nil
            }
        }
        .task(id: isExpanded) {
            guard isExpanded else { return }
            // Let the expansion transition/layout settle before requesting focus.
            try? await _Concurrency.Task.sleep(nanoseconds: 80_000_000)
            focus = .title
        }
        .onChange(of: projects.count) { _, _ in
            restoreLastUsedProjectSelection()
        }
    }

    private func restoreLastUsedProjectSelection() {
        guard let raw = UserDefaults.standard.string(forKey: LastUsedSelectionStore.key),
              let projectId = TaskCategoryKey.projectId(from: raw),
              let project = projects.first(where: { $0.id == projectId }) else { return }
        selection = .project(project)
    }

    @ViewBuilder
    private var customProjectsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if projects.isEmpty == false {
                FlowLayout(spacing: 10, rowSpacing: 10) {
                    ForEach(projects) { project in
                        CustomProjectPill(
                            name: project.name,
                            color: Color(hex: project.colorHex) ?? violet,
                            isSelected: isProjectSelected(project)
                        ) {
                            selectProject(project)
                        } onDelete: {
                            deleteProject(project)
                        }
                    }
                }
            }

            if isCreatingProject {
                HStack(spacing: 8) {
                    TextField("Project name", text: $newProjectName)
                        .focused($focus, equals: .newProjectName)
                        .font(.spaceGrotesk(.medium, size: 13))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Button("Create") {
                        createProject()
                    }
                    .font(.spaceGrotesk(.bold, size: 13))
                    .foregroundStyle(violet)
                    .disabled(!canCreateProject)

                    Button("Cancel") {
                        isCreatingProject = false
                        newProjectName = ""
                    }
                    .font(.spaceGrotesk(.semibold, size: 13))
                    .foregroundStyle(Color.secondary)
                }
            } else {
                Button {
                    isCreatingProject = true
                    DispatchQueue.main.async { focus = .newProjectName }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("New project")
                            .font(.spaceGrotesk(.semibold, size: 13))
                    }
                    .foregroundStyle(violet)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        Capsule()
                            .strokeBorder(violet.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(sectionBorder)
                .frame(height: 1)
                .offset(y: -6)
        }
    }

    private func isBuiltinSelected(_ category: Category) -> Bool {
        if case .builtin(let selected) = selection { return selected == category }
        return false
    }

    private func isProjectSelected(_ project: Project) -> Bool {
        if case .project(let selected) = selection { return selected.id == project.id }
        return false
    }

    private func selectBuiltin(_ category: Category) {
        selection = .builtin(category)
        LastUsedSelectionStore.save(selection)
    }

    private func selectProject(_ project: Project) {
        selection = .project(project)
        LastUsedSelectionStore.save(selection)
    }

    private func createProject() {
        guard canCreateProject else { return }
        let colorHex = ProjectColorCycle.colorHex(at: projects.count)
        let project = Project(name: trimmedNewProjectName, colorHex: colorHex)
        modelContext.insert(project)
        selection = .project(project)
        LastUsedSelectionStore.save(selection)
        newProjectName = ""
        isCreatingProject = false
    }

    private func deleteProject(_ project: Project) {
        if case .project(let selected) = selection, selected.id == project.id {
            selection = .builtin(.work)
            LastUsedSelectionStore.save(selection)
        }
        modelContext.delete(project)
    }

    private func clampedScheduleDate(_ date: Date) -> Date {
        let start = DateHelpers.startOfToday()
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        if day < start { return start }
        if day > scheduleRange.upperBound { return scheduleRange.upperBound }
        return day
    }

    private func submitIfPossible() {
        guard canSubmit else { return }
        let schedule = clampedScheduleDate(scheduledDate)
        onSubmit(trimmedTitle, selection, schedule, recurrenceInput)
        title = ""
        scheduledDate = DateHelpers.startOfToday()
        isRepeatEnabled = false
        selectedRecurrenceRule = .daily
        customWeekdays = []
        collapse()
    }

    private func collapse() {
        withAnimation(.easeOut(duration: 0.15)) {
            isExpanded = false
        }
    }
}

private enum LastUsedSelectionStore {
    static let key = "lastUsedCategorySelection"

    static func load() -> CategorySelection? {
        guard let raw = UserDefaults.standard.string(forKey: key) else { return nil }
        if let category = Category(rawValue: raw) {
            return .builtin(category)
        }
        return nil
    }

    static func save(_ selection: CategorySelection) {
        switch selection {
        case .builtin(let category):
            UserDefaults.standard.set(category.rawValue, forKey: key)
        case .project(let project):
            UserDefaults.standard.set(TaskCategoryKey.rawValue(projectId: project.id), forKey: key)
        }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat
    let rowSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            if x > 0 { x += spacing }
            x += size.width
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    @Previewable @State var expanded = true
    return VStack {
        AddTaskInlineForm(isExpanded: $expanded) { _, _, _, _ in }
            .padding()
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(try! ModelContainer(for: Task.self, Project.self))
}
