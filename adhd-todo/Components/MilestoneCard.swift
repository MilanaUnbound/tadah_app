import SwiftUI

struct MilestoneCard: View {
    let streakCount: Int

    private let yellow = Color(red: 0xFF / 255, green: 0xCC / 255, blue: 0x00 / 255)

    private var message: String? {
        switch streakCount {
        case 3:
            "3-day streak — building momentum."
        case 7:
            "One full week. Seriously impressive."
        case 14:
            "Two weeks straight. This is a habit now."
        case 30:
            "30 days. You are unstoppable."
        default:
            nil
        }
    }

    var body: some View {
        if let message {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.85))

                Text(message)
                    .font(.spaceGrotesk(.semibold, size: 13))
                    .foregroundStyle(Color.black.opacity(0.85))

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(yellow)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        MilestoneCard(streakCount: 3)
        MilestoneCard(streakCount: 7)
        MilestoneCard(streakCount: 14)
        MilestoneCard(streakCount: 30)
    }
    .padding()
}

