import SwiftUI

struct RecurrenceFormSection: View {
    @Binding var selectedRule: RecurrenceRule
    @Binding var customWeekdays: Set<Int>
    @Binding var hasEndDate: Bool
    @Binding var endDate: Date

    let startDate: Date
    let scheduleRangeUpperBound: Date

    @Environment(\.appTheme) private var theme

    private let violet = AppTheme.violet

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Repeat", selection: $selectedRule) {
                ForEach(RecurrenceRule.repeatableCases) { rule in
                    Text(rule.displayName).tag(rule)
                }
            }
            .pickerStyle(.segmented)

            if selectedRule == .custom {
                RecurrenceFormFlowLayout(spacing: 8, rowSpacing: 8) {
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

            HStack(spacing: 10) {
                Text("Ends")
                    .font(.spaceGrotesk(.medium, size: 13))
                    .foregroundStyle(theme.textSub)

                Spacer()

                Picker("Ends", selection: $hasEndDate) {
                    Text("No end").tag(false)
                    Text("Until").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }

            if hasEndDate {
                DatePicker(
                    "Until",
                    selection: $endDate,
                    in: startDate...scheduleRangeUpperBound,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: endDate) { _, newValue in
                    let clamped = max(newValue, startDate)
                    if clamped != newValue {
                        endDate = clamped
                    }
                }
            }
        }
    }

    var isValid: Bool {
        if selectedRule == .custom && customWeekdays.isEmpty { return false }
        return true
    }

    func makeInput() -> RecurrenceFormInput {
        RecurrenceFormInput(
            isEnabled: true,
            rule: selectedRule,
            customWeekdays: customWeekdays,
            end: hasEndDate
                ? .until(Calendar.current.startOfDay(for: max(endDate, startDate)))
                : .none
        )
    }
}

struct RecurrenceFormFlowLayout: Layout {
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
