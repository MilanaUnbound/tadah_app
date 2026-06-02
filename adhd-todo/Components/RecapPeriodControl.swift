import SwiftUI

enum RecapPeriodMode: String, CaseIterable, Identifiable {
    case month
    case year

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }
}

struct RecapPeriodControl: View {
    @Environment(\.screenContentWidth) private var screenContentWidth

    @Binding var periodMode: RecapPeriodMode
    let periodLabel: String
    let navigatorWidth: CGFloat
    let onPrevious: () -> Void
    let onNext: () -> Void

    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)
    private let inactiveText = Color(red: 0x88 / 255, green: 0x88 / 255, blue: 0x88 / 255)

    private var pillHorizontalPadding: CGFloat {
        ScreenLayout.periodPillHorizontalPadding(for: screenContentWidth)
    }

    private var pillFontSize: CGFloat {
        ScreenLayout.periodPillFontSize(for: screenContentWidth)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(RecapPeriodMode.allCases) { mode in
                    let isActive = mode == periodMode

                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            periodMode = mode
                        }
                    } label: {
                        Text(mode.label)
                            .font(.spaceGrotesk(.semibold, size: pillFontSize))
                            .foregroundStyle(isActive ? Color.white : inactiveText)
                            .padding(.horizontal, pillHorizontalPadding)
                            .frame(height: StreakBadgeLayout.rowControlHeight)
                            .background(isActive ? violet : Color.white)
                            .clipShape(Capsule())
                            .shadow(
                                color: isActive ? .clear : Color.black.opacity(0.08),
                                radius: 3,
                                x: 0,
                                y: 1
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 8)

            PeriodNavigatorCluster(
                label: periodLabel,
                width: navigatorWidth,
                contentAlignment: .trailing,
                onPrevious: onPrevious,
                onNext: onNext
            )
        }
        .frame(height: StreakBadgeLayout.rowControlHeight)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var mode: RecapPeriodMode = .month

        var body: some View {
            RecapPeriodControl(
                periodMode: $mode,
                periodLabel: "May",
                navigatorWidth: 96,
                onPrevious: {},
                onNext: {}
            )
            .frame(width: 360)
            .environment(\.screenContentWidth, 360)
            .padding()
        }
    }

    return PreviewWrapper()
}
