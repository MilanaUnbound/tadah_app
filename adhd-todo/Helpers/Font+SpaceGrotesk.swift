import SwiftUI

enum SpaceGroteskWeight {
    case light
    case regular
    case medium
    case semibold
    case bold
}

extension Font {
    static func spaceGrotesk(_ weight: SpaceGroteskWeight, size: CGFloat) -> Font {
        let name: String = switch weight {
        case .light: "SpaceGrotesk-Light"
        case .regular: "SpaceGrotesk-Regular"
        case .medium: "SpaceGrotesk-Medium"
        case .semibold: "SpaceGrotesk-SemiBold"
        case .bold: "SpaceGrotesk-Bold"
        }

        return .custom(name, size: size)
    }
}

