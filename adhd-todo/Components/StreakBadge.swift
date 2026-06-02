import SwiftUI

struct StreakBadge: View {
    let streakCount: Int

    private var streakColor: Color {
        switch streakCount {
        case 1...3:
            Color(red: 0xFF / 255, green: 0x33 / 255, blue: 0x99 / 255) // pink
        case 4...6:
            Color(red: 0xE0 / 255, green: 0x40 / 255, blue: 0xFB / 255) // fuchsia
        case 7...13:
            Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255) // violet
        case 14...:
            Color(red: 0xFF / 255, green: 0xCC / 255, blue: 0x00 / 255) // yellow
        default:
            Color(red: 0x9C / 255, green: 0xA3 / 255, blue: 0xAF / 255) // gray
        }
    }

    private var dayLabel: String {
        streakCount == 1 ? "day" : "days"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .semibold))

            Text("\(streakCount)")
                .font(.spaceGrotesk(.bold, size: 16))

            Text(dayLabel)
                .font(.spaceGrotesk(.semibold, size: 12))
                .opacity(0.9)
        }
        .foregroundStyle(streakColor)
        .padding(.horizontal, 14)
        .frame(height: StreakBadgeLayout.rowControlHeight)
        .background(streakColor.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(streakColor.opacity(0.19), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 12) {
        StreakBadge(streakCount: 0)
        StreakBadge(streakCount: 2)
        StreakBadge(streakCount: 5)
        StreakBadge(streakCount: 9)
        StreakBadge(streakCount: 21)
    }
    .padding()
}

