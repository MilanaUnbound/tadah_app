import SwiftUI

struct RescheduleSheet: View {
    let task: Task
    let seriesTasks: [Task]
    let onConfirm: (ScheduleSheetResult) -> Void
    let onCancel: () -> Void

    @Environment(\.appTheme) private var theme

    @State private var viewYear: Int
    @State private var viewMonth: Int
    @State private var selectedDateKey: String
    @State private var dragDismiss = BottomSheetDragDismissState()
    @State private var editScope: ScheduleEditScope = .thisDateOnly
    @State private var selectedRule: RecurrenceRule
    @State private var customWeekdays: Set<Int>
    @State private var repeatHasEndDate: Bool
    @State private var repeatEndDate: Date

    private let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    private var isRecurring: Bool { task.isRecurringInstance }

    private var scheduleRangeUpperBound: Date {
        let start = DateHelpers.startOfToday()
        return Calendar.current.date(byAdding: .year, value: 2, to: start) ?? start
    }

    init(
        task: Task,
        seriesTasks: [Task],
        onConfirm: @escaping (ScheduleSheetResult) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.task = task
        self.seriesTasks = seriesTasks
        self.onConfirm = onConfirm
        self.onCancel = onCancel

        let initialKey = DateHelpers.dateKey(for: task.resolvedScheduledDate)
        let calendar = Calendar.current
        let initialDate = task.resolvedScheduledDate
        _viewYear = State(initialValue: calendar.component(.year, from: initialDate))
        _viewMonth = State(initialValue: calendar.component(.month, from: initialDate))
        _selectedDateKey = State(initialValue: initialKey)

        let inferred = RecurrenceSeriesHelper.inferFormInput(for: task, seriesTasks: seriesTasks)
        _selectedRule = State(initialValue: inferred.rule)
        _customWeekdays = State(initialValue: inferred.customWeekdays)
        switch inferred.end {
        case .none:
            _repeatHasEndDate = State(initialValue: false)
            _repeatEndDate = State(initialValue: initialDate)
        case .until(let date):
            _repeatHasEndDate = State(initialValue: true)
            _repeatEndDate = State(initialValue: date)
        }
    }

    private var monthLabel: String {
        DateHelpers.monthYearLabel(year: viewYear, month: viewMonth)
    }

    private var todayKey: String {
        DateHelpers.todayKey()
    }

    private var selectedStartDate: Date {
        DateHelpers.date(fromKey: selectedDateKey)
            ?? task.resolvedScheduledDate
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

    private var confirmEnabled: Bool {
        guard selectedDateKey.isEmpty == false,
              DateHelpers.isPastKey(selectedDateKey) == false else {
            return false
        }

        if isRecurring && editScope == .allUpcoming {
            if selectedRule == .custom && customWeekdays.isEmpty { return false }
        }

        return true
    }

    private var confirmTitle: String {
        guard confirmEnabled,
              let date = DateHelpers.date(fromKey: selectedDateKey) else {
            return "Pick a date"
        }

        if isRecurring && editScope == .allUpcoming {
            return "Update schedule"
        }

        return "Set to \(DateHelpers.shortMonthDay(for: date))"
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

    private var maxSheetHeight: CGFloat {
        UIScreen.main.bounds.height * 0.88
    }

    private let sheetHeaderHeight: CGFloat = 72

    private var sheetPanel: some View {
        VStack(spacing: 0) {
            sheetHeader

            AppScrollView {
                VStack(spacing: 16) {
                    if isRecurring {
                        Picker("Apply to", selection: $editScope) {
                            Text("This date only").tag(ScheduleEditScope.thisDateOnly)
                            Text("All upcoming").tag(ScheduleEditScope.allUpcoming)
                        }
                        .pickerStyle(.segmented)
                    }

                    calendarSection

                    if isRecurring && editScope == .allUpcoming {
                        RecurrenceFormSection(
                            selectedRule: $selectedRule,
                            customWeekdays: $customWeekdays,
                            hasEndDate: $repeatHasEndDate,
                            endDate: $repeatEndDate,
                            startDate: selectedStartDate,
                            scheduleRangeUpperBound: scheduleRangeUpperBound
                        )
                    }

                    confirmButton

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
            .frame(maxHeight: max(0, maxSheetHeight - sheetHeaderHeight))
        }
        .frame(maxWidth: 390)
        .frame(maxHeight: maxSheetHeight)
        .frame(maxWidth: .infinity)
        .background(theme.sheet)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24
            )
        )
    }

    private var sheetHeader: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(theme.border)
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 4)

            Text(isRecurring ? "Schedule" : "Reschedule")
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

    private var confirmButton: some View {
        Button {
            guard confirmEnabled,
                  let date = DateHelpers.date(fromKey: selectedDateKey) else { return }

            let recurrenceInput: RecurrenceFormInput?
            if isRecurring && editScope == .allUpcoming {
                recurrenceInput = RecurrenceFormInput(
                    isEnabled: true,
                    rule: selectedRule,
                    customWeekdays: customWeekdays,
                    end: repeatHasEndDate
                        ? .until(Calendar.current.startOfDay(for: max(repeatEndDate, selectedStartDate)))
                        : .none
                )
            } else {
                recurrenceInput = nil
            }

            onConfirm(
                ScheduleSheetResult(
                    selectedDate: date,
                    scope: isRecurring ? editScope : nil,
                    recurrenceInput: recurrenceInput
                )
            )
        } label: {
            Text(confirmTitle)
                .font(.spaceGrotesk(.semibold, size: 15))
                .foregroundStyle(confirmEnabled ? Color.white : theme.textFaint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(confirmEnabled ? AppTheme.violet : theme.btnBg)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!confirmEnabled)
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
        let isPast = DateHelpers.isPastKey(dateKey)
        let isSelected = selectedDateKey == dateKey
        let isToday = dateKey == todayKey

        return Button {
            guard !isPast else { return }
            selectedDateKey = dateKey
        } label: {
            Text("\(day)")
                .font(.spaceGrotesk(isSelected || isToday ? .bold : .regular, size: 14))
                .foregroundStyle(
                    isSelected ? Color.white :
                        isPast ? theme.textFaint :
                        isToday ? AppTheme.violet : theme.text
                )
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    isSelected ? AppTheme.violet : Color.clear,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .overlay {
                    if isToday && !isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppTheme.violet, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(isPast)
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
    RescheduleSheet(
        task: Task(
            title: "Buy groceries",
            category: .groceries,
            dateKey: DateHelpers.todayKey()
        ),
        seriesTasks: [],
        onConfirm: { _ in },
        onCancel: {}
    )
    .withAppTheme()
}
