import SwiftUI

struct HistoryProjectSearchBar: View {
    @Binding var text: String

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.textFaint)

            TextField("Search projects…", text: $text)
                .font(.spaceGrotesk(.medium, size: 14))
                .foregroundStyle(theme.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 1)
    }
}
