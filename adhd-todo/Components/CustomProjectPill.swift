import SwiftUI

struct CustomProjectPill: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onSelect) {
                Text(name)
                    .font(.spaceGrotesk(.semibold, size: 12))
                    .foregroundStyle(isSelected ? Color.white : color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isSelected ? color : color.opacity(0.12))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.textMuted)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete project \(name)")
        }
    }
}
