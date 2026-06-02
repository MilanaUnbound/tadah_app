import SwiftUI

enum StreakBadgeLayout {
    static let defaultWidth: CGFloat = 96

    /// Shared row height for streak pill, period toggles, and navigator (reference layout).
    static let rowControlHeight: CGFloat = 34
    static let navigatorMinWidth: CGFloat = 96
    static let navigatorLabelMinWidth: CGFloat = 44
    static let navigatorSpacing: CGFloat = 2
    static let navigatorChevronPadding: CGFloat = 4

    static func navigatorContainerWidth(streakWidth: CGFloat) -> CGFloat {
        max(streakWidth, navigatorMinWidth)
    }
}

private struct StreakWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { StreakBadgeLayout.defaultWidth }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func streakWidthReporter() -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: StreakWidthPreferenceKey.self, value: geo.size.width)
            }
        )
    }

    func onStreakWidth(_ action: @escaping (CGFloat) -> Void) -> some View {
        onPreferenceChange(StreakWidthPreferenceKey.self, perform: action)
    }
}
