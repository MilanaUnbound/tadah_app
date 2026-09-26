import SwiftUI

struct HistoryPeriodControl: View {
    @Environment(\.screenContentWidth) private var screenContentWidth
    @Environment(\.appTheme) private var theme

    @Binding var period: HistoryPeriod
    let periodLabel: String
    let navigatorWidth: CGFloat
    let showsNavigation: Bool
    var onPeriodChange: () -> Void = {}
    let onPrevious: () -> Void
    let onNext: () -> Void

    private var pillHorizontalPadding: CGFloat {
        ScreenLayout.periodPillHorizontalPadding(for: screenContentWidth)
    }

    private var pillFontSize: CGFloat {
        ScreenLayout.periodPillFontSize(for: screenContentWidth)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            singleRowLayout
            wrappedLayout
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pillRow: some View {
        HStack(spacing: 6) {
            ForEach(HistoryPeriod.allCases) { item in
                periodPill(for: item)
            }
        }
    }

    private var singleRowLayout: some View {
        HStack(alignment: .center, spacing: 6) {
            pillRow

            if showsNavigation {
                Spacer(minLength: 8)

                PeriodNavigatorCluster(
                    label: periodLabel,
                    width: navigatorWidth,
                    contentAlignment: .trailing,
                    onPrevious: onPrevious,
                    onNext: onNext
                )
            }
        }
        .frame(height: StreakBadgeLayout.rowControlHeight)
    }

    private var wrappedLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            pillRow

            if showsNavigation {
                PeriodNavigatorCluster(
                    label: periodLabel,
                    width: navigatorWidth,
                    contentAlignment: .leading,
                    onPrevious: onPrevious,
                    onNext: onNext
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func periodPill(for item: HistoryPeriod) -> some View {
        let isActive = item == period

        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                period = item
                onPeriodChange()
            }
        } label: {
            Text(item.label)
                .font(.spaceGrotesk(.semibold, size: pillFontSize))
                .foregroundStyle(isActive ? Color.white : theme.textSub)
                .padding(.horizontal, pillHorizontalPadding)
                .frame(height: StreakBadgeLayout.rowControlHeight)
                .background(isActive ? AppTheme.violet : theme.card)
                .clipShape(Capsule())
                .shadow(
                    color: isActive ? .clear : theme.cardShadowColor,
                    radius: 3,
                    x: 0,
                    y: 1
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview("History period — wide") {
    struct PreviewWrapper: View {
        @State private var period: HistoryPeriod = .month

        var body: some View {
            HistoryPeriodControl(
                period: $period,
                periodLabel: "May",
                navigatorWidth: 96,
                showsNavigation: period != .project,
                onPrevious: {},
                onNext: {}
            )
            .frame(width: 390)
            .environment(\.screenContentWidth, 390)
            .withAppTheme()
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("History period — narrow") {
    struct PreviewWrapper: View {
        @State private var period: HistoryPeriod = .month

        var body: some View {
            HistoryPeriodControl(
                period: $period,
                periodLabel: "Sep",
                navigatorWidth: 96,
                showsNavigation: true,
                onPrevious: {},
                onNext: {}
            )
            .frame(width: 360)
            .environment(\.screenContentWidth, 360)
            .withAppTheme()
            .padding()
        }
    }

    return PreviewWrapper()
}
