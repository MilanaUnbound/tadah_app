import Foundation

enum ProjectColorCycle {
    static let palette: [String] = [
        "#7B2FFF",
        "#3B82F6",
        "#22C55E",
        "#C084FC",
        "#F59E0B",
        "#F97316",
        "#EC4899",
    ]

    static var defaultHex: String { palette[0] }

    static func colorHex(at index: Int) -> String {
        palette[index % palette.count]
    }
}
