import SwiftUI

struct HistoryMonthYearPickerSheet: View {
    enum Step {
        case year
        case month
    }

    let availableYears: [Int]
    let initialYear: Int
    let initialMonth: Int
    let onConfirm: (_ year: Int, _ month: Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var step: Step = .year
    @State private var selectedYear: Int
    @State private var selectedMonth: Int

    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)

    private static let monthSymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = .current
        return formatter.monthSymbols
    }()

    init(
        availableYears: [Int],
        initialYear: Int,
        initialMonth: Int,
        onConfirm: @escaping (_ year: Int, _ month: Int) -> Void
    ) {
        self.availableYears = availableYears
        self.initialYear = initialYear
        self.initialMonth = initialMonth
        self.onConfirm = onConfirm
        _selectedYear = State(initialValue: initialYear)
        _selectedMonth = State(initialValue: initialMonth)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .year:
                    yearList
                case .month:
                    monthList
                }
            }
            .navigationTitle(step == .year ? "Pick a year" : "Pick a month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if step == .month {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            step = .year
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Year")
                            }
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Confirm") {
                            onConfirm(selectedYear, selectedMonth)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var yearList: some View {
        List {
            ForEach(availableYears, id: \.self) { year in
                Button {
                    selectedYear = year
                    step = .month
                } label: {
                    HStack {
                        Text(String(year))
                            .font(.spaceGrotesk(.semibold, size: 16))
                            .foregroundStyle(year == selectedYear ? violet : Color.primary)
                        Spacer()
                        if year == selectedYear {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(violet)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }

    private var monthList: some View {
        List {
            Section {
                Text(String(selectedYear))
                    .font(.spaceGrotesk(.medium, size: 13))
                    .foregroundStyle(Color.secondary)
            }

            ForEach(1 ... 12, id: \.self) { month in
                Button {
                    selectedMonth = month
                } label: {
                    HStack {
                        Text(monthName(for: month))
                            .font(.spaceGrotesk(.semibold, size: 16))
                            .foregroundStyle(month == selectedMonth ? violet : Color.primary)
                        Spacer()
                        if month == selectedMonth {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(violet)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }

    private func monthName(for month: Int) -> String {
        let index = month - 1
        guard index >= 0, index < Self.monthSymbols.count else {
            return "Month \(month)"
        }
        return Self.monthSymbols[index]
    }
}

#Preview {
    HistoryMonthYearPickerSheet(
        availableYears: [2026, 2025, 2024],
        initialYear: 2026,
        initialMonth: 5
    ) { _, _ in }
}
