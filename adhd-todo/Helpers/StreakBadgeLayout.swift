import SwiftUI

enum StreakBadgeLayout {
    /// Shared row height for period toggles and navigator (reference layout).
    static let rowControlHeight: CGFloat = 34
    static let navigatorMinWidth: CGFloat = 96
    static let navigatorLabelMinWidth: CGFloat = 44
    static let navigatorSpacing: CGFloat = 2
    static let navigatorChevronPadding: CGFloat = 4

    static func navigatorContainerWidth(width: CGFloat) -> CGFloat {
        max(width, navigatorMinWidth)
    }
}
