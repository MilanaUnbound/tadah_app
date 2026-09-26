import SwiftUI

struct AllDoneCard: View {
    let completedCount: Int

    private let purple = Color(red: 0xA8 / 255, green: 0x55 / 255, blue: 0xF7 / 255)

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.violet, purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Text("🎉")
                    .font(.system(size: 24))
                    .frame(width: 48, height: 48, alignment: .center)
            }
            .padding(.bottom, 16)

            VStack(spacing: 6) {
                Text("Tadah, you did it!")
                    .font(.spaceGrotesk(.bold, size: 22))
                    .tracking(-0.3)
                    .foregroundStyle(theme.text)
                    .multilineTextAlignment(.center)

                Text("\(completedCount) \(completedCount == 1 ? "task" : "tasks") completed")
                    .font(.spaceGrotesk(.medium, size: 14))
                    .foregroundStyle(theme.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.violet.opacity(0.08), radius: 12, x: 0, y: 2)
        .padding(.top, 8)
    }
}

#Preview {
    AllDoneCard(completedCount: 4)
        .padding()
        .background(Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255))
}
