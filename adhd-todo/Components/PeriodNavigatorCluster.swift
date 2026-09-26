import SwiftUI

struct PeriodNavigatorCluster: View {
    let label: String
    let width: CGFloat
    var labelColor: Color?
    var chevronColor: Color?
    var contentAlignment: Alignment = .trailing
    let onPrevious: () -> Void
    let onNext: () -> Void

    @Environment(\.appTheme) private var theme

    private var resolvedLabelColor: Color {
        labelColor ?? theme.text
    }

    private var resolvedChevronColor: Color {
        chevronColor ?? theme.textSub
    }

    private var containerWidth: CGFloat {
        StreakBadgeLayout.navigatorContainerWidth(width: width)
    }

    var body: some View {
        HStack(spacing: StreakBadgeLayout.navigatorSpacing) {
            navButton(systemName: "chevron.left", action: onPrevious)

            Text(label)
                .font(.spaceGrotesk(.medium, size: 14))
                .foregroundStyle(resolvedLabelColor)
                .lineLimit(1)
                .frame(minWidth: StreakBadgeLayout.navigatorLabelMinWidth)
                .multilineTextAlignment(.center)

            navButton(systemName: "chevron.right", action: onNext)
        }
        .frame(height: StreakBadgeLayout.rowControlHeight)
        .frame(width: containerWidth, alignment: contentAlignment)
    }

    private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(resolvedChevronColor)
                .padding(.horizontal, StreakBadgeLayout.navigatorChevronPadding)
                .frame(maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview("Compact navigator") {
    VStack(spacing: 24) {
        PeriodNavigatorCluster(label: "May", width: 96, onPrevious: {}, onNext: {})
        PeriodNavigatorCluster(label: "January", width: 96, labelColor: AppTheme.light.textMuted, chevronColor: AppTheme.light.textMuted, onPrevious: {}, onNext: {})
        PeriodNavigatorCluster(label: "2026", width: 96, onPrevious: {}, onNext: {})
    }
    .withAppTheme()
    .padding()
}
