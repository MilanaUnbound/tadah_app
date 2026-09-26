import SwiftUI

struct HistoryCompletedTaskRow: View {
    let task: Task
    let projects: [Project]
    let onTagTap: () -> Void

    @Environment(\.appTheme) private var theme

    private var displayColor: Color {
        TaskCategoryDisplay.displayColor(for: task, projects: projects)
    }

    private var displayName: String {
        TaskCategoryDisplay.displayName(for: task, projects: projects)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(displayColor)
                    .frame(width: 20, height: 20)

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white)
            }

            Text(task.title)
                .font(.spaceGrotesk(.medium, size: 15))
                .foregroundStyle(theme.textSub)
                .strikethrough()
                .lineLimit(2)

            Spacer(minLength: 0)

            Button(action: onTagTap) {
                Text(displayName)
                    .font(.spaceGrotesk(.medium, size: 12))
                    .foregroundStyle(displayColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(displayColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 1)
    }
}
