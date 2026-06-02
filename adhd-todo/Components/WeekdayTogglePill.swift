import SwiftUI

struct WeekdayTogglePill: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)

    var body: some View {
        Button {
            onTap()
        } label: {
            Text(label)
                .font(.spaceGrotesk(.semibold, size: 12))
                .foregroundStyle(isSelected ? Color.white : violet)
                .frame(minWidth: 32)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(isSelected ? violet : violet.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Monday-first weekday options for custom recurrence (Calendar weekday 1…7).
struct WeekdayPickerOption: Identifiable {
    let id: Int
    let label: String

    static var mondayFirstOptions: [WeekdayPickerOption] {
        // Calendar: 1 = Sunday … 7 = Saturday — show Mon–Sun.
        let order = [2, 3, 4, 5, 6, 7, 1]
        let symbols = ["M", "T", "W", "T", "F", "S", "S"]
        return zip(order, symbols).map { WeekdayPickerOption(id: $0.0, label: $0.1) }
    }
}

#Preview {
    HStack {
        WeekdayTogglePill(label: "M", isSelected: true, onTap: {})
        WeekdayTogglePill(label: "W", isSelected: false, onTap: {})
    }
    .padding()
}
