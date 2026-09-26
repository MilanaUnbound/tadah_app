import SwiftUI

struct HistoryProjectRow: View {
    let summary: HistoryProjectSummary
    let onTap: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Circle()
                    .fill(summary.color)
                    .frame(width: 10, height: 10)

                Text(summary.displayName)
                    .font(.spaceGrotesk(.medium, size: 15))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text("\(summary.doneCount)/\(summary.totalCount)")
                    .font(.spaceGrotesk(.medium, size: 13))
                    .foregroundStyle(theme.textFaint)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.progressBg)
                        .frame(width: 40, height: 4)

                    Capsule()
                        .fill(summary.color)
                        .frame(width: 40 * CGFloat(summary.percent) / 100, height: 4)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.checkBorder)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
