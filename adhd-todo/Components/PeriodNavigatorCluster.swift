import SwiftUI

struct PeriodNavigatorCluster: View {
    let label: String
    let width: CGFloat
    var contentAlignment: Alignment = .trailing
    let onPrevious: () -> Void
    let onNext: () -> Void

    private let labelGray = Color(red: 0xAA / 255, green: 0xAA / 255, blue: 0xAA / 255)

    private var containerWidth: CGFloat {
        StreakBadgeLayout.navigatorContainerWidth(streakWidth: width)
    }

    var body: some View {
        HStack(spacing: StreakBadgeLayout.navigatorSpacing) {
            navButton(systemName: "chevron.left", action: onPrevious)

            Text(label)
                .font(.spaceGrotesk(.medium, size: 14))
                .foregroundStyle(labelGray)
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
                .foregroundStyle(labelGray)
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
        PeriodNavigatorCluster(label: "Sep", width: 96, onPrevious: {}, onNext: {})
        PeriodNavigatorCluster(label: "2026", width: 96, onPrevious: {}, onNext: {})
        PeriodNavigatorCluster(label: "Sep", width: 120, onPrevious: {}, onNext: {})
    }
    .padding()
}
