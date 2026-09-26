import SwiftUI

struct SettingRow<Trailing: View>: View {
    let icon: AnyView
    let label: String
    let hint: String?
    @ViewBuilder let trailing: () -> Trailing

    init(
        icon: some View,
        label: String,
        hint: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.icon = AnyView(icon)
        self.label = label
        self.hint = hint
        self.trailing = trailing
    }

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            icon
                .frame(width: 34, height: 34)
                .background(theme.btnBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.spaceGrotesk(.medium, size: 15))
                    .foregroundStyle(theme.text)

                if let hint {
                    Text(hint)
                        .font(.spaceGrotesk(.regular, size: 12))
                        .foregroundStyle(theme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 1)
        .padding(.bottom, 8)
    }
}
