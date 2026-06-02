import SwiftUI

enum ScreenLayout {
    static let defaultContentWidth: CGFloat = 390

    static func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minValue), maxValue)
    }

    /// `clamp(14px, 5vw, 20px)`
    static func sidePadding(for width: CGFloat) -> CGFloat {
        clamp(width * 0.05, min: 14, max: 20)
    }

    /// `clamp(26px, 8vw, 34px)`
    static func headingFontSize(for width: CGFloat) -> CGFloat {
        clamp(width * 0.08, min: 26, max: 34)
    }

    /// `clamp(10px, 3.5vw, 18px)` — period pill horizontal padding
    static func periodPillHorizontalPadding(for width: CGFloat) -> CGFloat {
        clamp(width * 0.035, min: 10, max: 18)
    }

    /// `clamp(12px, 3.5vw, 14px)` — period pill label
    static func periodPillFontSize(for width: CGFloat) -> CGFloat {
        clamp(width * 0.035, min: 12, max: 14)
    }

    /// `clamp(18px, 6vw, 26px)` — recap summary card value
    static func summaryValueFontSize(for width: CGFloat) -> CGFloat {
        clamp(width * 0.06, min: 18, max: 26)
    }
}

// MARK: - Environment

private struct ScreenContentWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = ScreenLayout.defaultContentWidth
}

extension EnvironmentValues {
    var screenContentWidth: CGFloat {
        get { self[ScreenContentWidthKey.self] }
        set { self[ScreenContentWidthKey.self] = newValue }
    }
}

// MARK: - View helpers

extension View {
    /// Vertical-only insets for tab scroll content; horizontal padding comes from `ContentView`.
    func tabContentVerticalPadding() -> some View {
        padding(.top, 16).padding(.bottom, 16)
    }
}
