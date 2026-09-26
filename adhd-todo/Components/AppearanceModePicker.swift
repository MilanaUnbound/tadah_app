import SwiftUI

struct AppearanceModePicker: View {
    @Binding var selection: AppearanceMode

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme")
                .font(.spaceGrotesk(.medium, size: 15))
                .foregroundStyle(theme.text)

            HStack(spacing: 8) {
                ForEach(AppearanceMode.allCases) { mode in
                    modeButton(mode)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 1)
        .padding(.bottom, 8)
    }

    private func modeButton(_ mode: AppearanceMode) -> some View {
        let isActive = selection == mode

        return Button {
            selection = mode
        } label: {
            VStack(spacing: 6) {
                Image(systemName: mode.systemImageName)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(isActive ? Color.white : theme.textSub)

                Text(mode.label)
                    .font(.spaceGrotesk(isActive ? .semibold : .regular, size: 12))
                    .foregroundStyle(isActive ? Color.white : theme.textSub)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                isActive ? AppTheme.violet : theme.btnBg,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AppearanceModePicker(selection: .constant(.auto))
        .padding()
}
