import SwiftUI

struct RecurringInstancePickerSheet: View {
    let title: String
    let instances: [Task]
    let onComplete: (Task) -> Void
    let onDelete: (Task) -> Void
    let onCancel: () -> Void

    @Environment(\.appTheme) private var theme

    @State private var viewYear: Int
    @State private var viewMonth: Int
    @State private var selectedDateKey: String
    @State private var dragDismiss = BottomSheetDragDismissState()

    private let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    private var instanceDateKeys: Set<String> {
        Set(instances.map(\.dateKey))
    }

    private var taskForDateKey: [String: Task] {
        Dictionary(uniqueKeysWithValues: instances.map { ($0.dateKey, $0) })
    }

    private var selectedTask: Task? {
        taskForDateKey[selectedDateKey]
    }

    private var actionEnabled: Bool {
        selectedTask != nil
    }

    init(
        title: String,
        instances: [Task],
        onComplete: @escaping (Task) -> Void,
        onDelete: @escaping (Task) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.instances = instances
        self.onComplete = onComplete
        self.onDelete = onDelete
        self.onCancel = onCancel

        let sorted = instances.sorted { $0.dateKey < $1.dateKey }
        let initial = sorted.first?.resolvedScheduledDate ?? DateHelpers.startOfToday()
        let calendar = Calendar.current
        let initialKey = sorted.first.map(\.dateKey) ?? ""

        _viewYear = State(initialValue: calendar.component(.year, from: initial))
        _viewMonth = State(initialValue: calendar.component(.month, from: initial))
        _selectedDateKey = State(initialValue: initialKey)
    }

    private var monthLabel: String {
        DateHelpers.monthYearLabel(year: viewYear, month: viewMonth)
    }

    private var todayKey: String {
        DateHelpers.todayKey()
    }

    private var calendarCells: [Int?] {
        var calendar = Calendar.current
        calendar.firstWeekday = 1

        var comps = DateComponents()
        comps.year = viewYear
        comps.month = viewMonth
        comps.day = 1
        guard let firstOfMonth = calendar.date(from: comps),
              let dayRange = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        let weekdayOffset = calendar.component(.weekday, from: firstOfMonth) - 1
        var cells: [Int?] = Array(repeating: nil, count: weekdayOffset)
        cells.append(contentsOf: dayRange.map { Optional($0) })

        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(dragDismiss.backdropOpacity(base: 0.25))
                .ignoresSafeArea()
                .onTapGesture {
                    dragDismiss.dismissAnimated(onDismiss: onCancel)
                }

            sheetPanel
                .bottomSheetPanel(state: dragDismiss)
        }
    }

    private var sheetPanel: some View {
        VStack(spacing: 0) {
            sheetHeader

            VStack(spacing: 16) {
                calendarSection

                Button {
                    guard let task = selectedTask else { return }
                    onComplete(task)
                } label: {
                    Text(completeButtonTitle)
                        .font(.spaceGrotesk(.semibold, size: 15))
                        .foregroundStyle(actionEnabled ? Color.white : theme.textFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(actionEnabled ? AppTheme.violet : theme.btnBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!actionEnabled)

                Button {
                    guard let task = selectedTask else { return }
                    onDelete(task)
                } label: {
                    Text(deleteButtonTitle)
                        .font(.spaceGrotesk(.semibold, size: 15))
                        .foregroundStyle(actionEnabled ? Color(red: 0xEF / 255, green: 0x44 / 255, blue: 0x44 / 255) : theme.textFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.btnBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!actionEnabled)

                Button {
                    dragDismiss.dismissAnimated(onDismiss: onCancel)
                } label: {
                    Text("Cancel")
                        .font(.spaceGrotesk(.semibold, size: 14))
                        .foregroundStyle(theme.textSub)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: 390)
        .frame(maxWidth: .infinity)
        .background(theme.sheet)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24
            )
        )
    }

    private var completeButtonTitle: String {
        guard actionEnabled,
              let date = DateHelpers.date(fromKey: selectedDateKey) else {
            return "Mark complete"
        }
        return "Mark complete · \(DateHelpers.shortMonthDay(for: date))"
    }

    private var deleteButtonTitle: String {
        guard actionEnabled,
              let date = DateHelpers.date(fromKey: selectedDateKey) else {
            return "Delete this day"
        }
        return "Delete this day · \(DateHelpers.shortMonthDay(for: date))"
    }

    private var sheetHeader: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(theme.border)
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 4)

            Text(title)
                .font(.spaceGrotesk(.bold, size: 18))
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .contentShape(Rectangle())
        .gesture(dragDismiss.dragGesture(onDismiss: onCancel))
    }

    private var calendarSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    stepMonth(direction: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(theme.textSub)
                        .padding(4)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthLabel)
                    .font(.spaceGrotesk(.semibold, size: 15))
                    .foregroundStyle(theme.text)

                Spacer()

                Button {
                    stepMonth(direction: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(theme.textSub)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 16)

            calendarGrid
        }
    }

    private var calendarGrid: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.spaceGrotesk(.medium, size: 12))
                        .foregroundStyle(theme.textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)
                }
            }

            ForEach(Array(calendarRows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, day in
                        if let day {
                            dayCell(day: day)
                        } else {
                            Color.clear
                                .frame(height: 38)
                        }
                    }
                }
            }
        }
    }

    private var calendarRows: [[Int?]] {
        stride(from: 0, to: calendarCells.count, by: 7).map { start in
            Array(calendarCells[start..<min(start + 7, calendarCells.count)])
        }
    }

    private func dayCell(day: Int) -> some View {
        let dateKey = dateKey(forDay: day)
        let hasInstance = instanceDateKeys.contains(dateKey)
        let isSelected = selectedDateKey == dateKey
        let isToday = dateKey == todayKey

        return Button {
            guard hasInstance else { return }
            selectedDateKey = dateKey
        } label: {
            Text("\(day)")
                .font(.spaceGrotesk(isSelected || isToday ? .bold : .regular, size: 14))
                .foregroundStyle(
                    isSelected ? Color.white :
                        !hasInstance ? theme.textFaint :
                        isToday ? AppTheme.violet : theme.text
                )
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    isSelected ? AppTheme.violet : Color.clear,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .overlay {
                    if isToday && !isSelected && hasInstance {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppTheme.violet, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!hasInstance)
    }

    private func dateKey(forDay day: Int) -> String {
        DateHelpers.dateKey(year: viewYear, month: viewMonth, day: day)
    }

    private func stepMonth(direction: Int) {
        HistoryBrowseHelper.stepMonth(
            viewYear: &viewYear,
            viewMonth: &viewMonth,
            direction: direction
        )
    }
}

#Preview {
    RecurringInstancePickerSheet(
        title: "Weekly lesson",
        instances: [
            Task(
                title: "Weekly lesson",
                category: .work,
                dateKey: DateHelpers.offsetKey(DateHelpers.todayKey(), byDays: 1) ?? DateHelpers.todayKey(),
                recurrenceRule: .weekly,
                recurrenceSeriesId: UUID()
            )
        ],
        onComplete: { _ in },
        onDelete: { _ in },
        onCancel: {}
    )
    .withAppTheme()
}
