import SwiftUI

struct AllDoneCard: View {
    let completedCount: Int

    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)
    private let purple = Color(red: 0xA8 / 255, green: 0x55 / 255, blue: 0xF7 / 255)
    private let subtitleGray = Color(red: 0xAA / 255, green: 0xAA / 255, blue: 0xAA / 255)

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : .white
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [violet, purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 16)

            VStack(spacing: 6) {
                Text("Tadah, you did it!")
                    .font(.spaceGrotesk(.bold, size: 22))
                    .tracking(-0.3)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)

                Text("\(completedCount) \(completedCount == 1 ? "task" : "tasks") completed")
                    .font(.spaceGrotesk(.medium, size: 14))
                    .foregroundStyle(subtitleGray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: violet.opacity(0.08), radius: 12, x: 0, y: 2)
        .padding(.top, 8)
    }
}

#Preview {
    AllDoneCard(completedCount: 4)
        .padding()
        .background(Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255))
}
