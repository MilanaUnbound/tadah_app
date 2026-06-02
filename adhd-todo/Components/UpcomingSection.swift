import SwiftUI

struct UpcomingSection: View {
    @Environment(CategoryPickerController.self) private var categoryPicker

    let tasks: [Task]
    let projects: [Project]
    let onReschedule: (_ task: Task, _ newDate: Date) -> Void
    let onDelete: (_ task: Task) -> Void

    @State private var isOpen = false
    @State private var activeTaskID: UUID? = nil
    @State private var draftDates: [UUID: Date] = [:]

    private let sectionLabel = Color(red: 0xAA / 255, green: 0xAA / 255, blue: 0xAA / 255)
    private let chevronColor = Color(red: 0xBB / 255, green: 0xBB / 255, blue: 0xBB / 255)
    private let trayBackground = Color(red: 0xFA / 255, green: 0xFA / 255, blue: 0xFA / 255)
    private let trayDivider = Color(red: 0xF0 / 255, green: 0xF0 / 255, blue: 0xF0 / 255)
    private let deleteBg = Color(red: 0xFF / 255, green: 0xF0 / 255, blue: 0xF0 / 255)
    private let deleteRed = Color(red: 0xEF / 255, green: 0x44 / 255, blue: 0x44 / 255)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    isOpen.toggle()
                    if isOpen == false {
                        activeTaskID = nil
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Upcoming · \(tasks.count)")
                        .font(.spaceGrotesk(.medium, size: 12))
                        .foregroundStyle(sectionLabel)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(chevronColor)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                        .animation(.easeOut(duration: 0.2), value: isOpen)

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(spacing: 8) {
                    ForEach(tasks) { task in
                        let isActive = activeTaskID == task.id
                        VStack(spacing: 0) {
                            UpcomingTaskRow(
                                task: task,
                                projects: projects,
                                isExpanded: isActive,
                                onTapRow: { toggleActive(task) },
                                onCategoryTap: { categoryPicker.present(task: task) }
                            )

                            if isActive {
                                tray(for: task)
                            }
                        }
                    }
                }
            }
        }
    }

    private func toggleActive(_ task: Task) {
        withAnimation(.easeOut(duration: 0.2)) {
            if activeTaskID == task.id {
                activeTaskID = nil
            } else {
                activeTaskID = task.id
                if draftDates[task.id] == nil {
                    draftDates[task.id] = task.resolvedScheduledDate
                }
            }
        }
    }

    private func tray(for task: Task) -> some View {
        let today = DateHelpers.startOfToday()
        let maxDate = Calendar.current.date(byAdding: .year, value: 2, to: today) ?? today
        let range: ClosedRange<Date> = today ... maxDate

        let selection = Binding<Date>(
            get: { draftDates[task.id] ?? task.resolvedScheduledDate },
            set: { newValue in
                draftDates[task.id] = newValue
            }
        )

        return HStack(spacing: 10) {
            DatePicker(
                "",
                selection: selection,
                in: range,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .onChange(of: selection.wrappedValue) { _, newValue in
                onReschedule(task, newValue)
                withAnimation(.easeOut(duration: 0.2)) {
                    activeTaskID = nil
                }
            }

            Button {
                onDelete(task)
                withAnimation(.easeOut(duration: 0.2)) {
                    activeTaskID = nil
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Delete")
                        .font(.spaceGrotesk(.medium, size: 13))
                }
                .foregroundStyle(deleteRed)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(deleteBg)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(trayBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(trayDivider)
                .frame(height: 1)
        }
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: 14,
                bottomTrailingRadius: 14
            )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private struct UpcomingTaskRow: View {
        let task: Task
        let projects: [Project]
        let isExpanded: Bool
        let onTapRow: () -> Void
        let onCategoryTap: () -> Void

        private let cardSurface = Color.white

        private var displayColor: Color {
            TaskCategoryDisplay.displayColor(for: task, projects: projects)
        }

        private var displayName: String {
            TaskCategoryDisplay.displayName(for: task, projects: projects)
        }

        private var dateLabel: String {
            DateHelpers.chipLabel(forKey: task.dateKey)
        }

        var body: some View {
            HStack(spacing: 12) {
                Circle()
                    .stroke(Color(red: 0xE0 / 255, green: 0xE0 / 255, blue: 0xE0 / 255), lineWidth: 2)
                    .fill(Color.clear)
                    .frame(width: 20, height: 20)

                Text(task.title)
                    .font(.spaceGrotesk(.medium, size: 15))
                    .foregroundStyle(Color(red: 0x66 / 255, green: 0x66 / 255, blue: 0x66 / 255))
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(dateLabel)
                    .font(.spaceGrotesk(.medium, size: 12))
                    .foregroundStyle(Color(red: 0xBB / 255, green: 0xBB / 255, blue: 0xBB / 255))

                Button(action: onCategoryTap) {
                    Text(displayName)
                        .font(.spaceGrotesk(.medium, size: 12))
                        .foregroundStyle(displayColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(displayColor.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTapRow)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(cardSurface)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 14,
                    bottomLeadingRadius: isExpanded ? 0 : 14,
                    bottomTrailingRadius: isExpanded ? 0 : 14,
                    topTrailingRadius: 14
                )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
            .opacity(0.75)
        }
    }
}

#Preview {
    UpcomingSection(
        tasks: [
            Task(title: "Book dentist", category: .health, dateKey: DateHelpers.todayKey())
        ],
        projects: [],
        onReschedule: { _, _ in },
        onDelete: { _ in }
    )
    .padding()
    .environment(CategoryPickerController())
    .modelContainer(for: [Task.self, Project.self], inMemory: true)
}

