import SwiftUI

struct RecapInsightCard: View {
    let categoryName: String
    let percent: Int
    let accentColor: Color
    var isCompact: Bool = false

    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)
    private let labelGray = Color(red: 0xAA / 255, green: 0xAA / 255, blue: 0xAA / 255)
    private let bodyText = Color(red: 0x22 / 255, green: 0x22 / 255, blue: 0x22 / 255)

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark
            ? violet.opacity(0.12)
            : Color(red: 0xF5 / 255, green: 0xF1 / 255, blue: 0xFF / 255)
    }

    private var bodyFontSize: CGFloat { isCompact ? 14 : 15 }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(violet)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Insight")
                    .font(.spaceGrotesk(.medium, size: 12))
                    .foregroundStyle(labelGray)
                    .tracking(0.3)

                insightSentence
                    .font(.spaceGrotesk(.medium, size: bodyFontSize))
                    .foregroundStyle(colorScheme == .dark ? Color.primary : bodyText)
            }
        }
        .padding(.vertical, isCompact ? 12 : 16)
        .padding(.horizontal, isCompact ? 14 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var insightSentence: Text {
        Text(categoryName)
            .font(.spaceGrotesk(.semibold, size: bodyFontSize))
            .foregroundStyle(accentColor)
        + Text(" leads with ")
        + Text("\(percent)%")
            .font(.spaceGrotesk(.semibold, size: bodyFontSize))
        + Text(" of your tasks.")
    }
}

#Preview {
    RecapInsightCard(
        categoryName: "Work",
        percent: 45,
        accentColor: CategoryDonutCard.donutColor(for: .work),
        isCompact: true
    )
    .padding()
}
