import SwiftUI

struct DragHandleView: View {
    @Environment(\.appTheme) private var theme

    var isCompleted: Bool = false

    private let dotSize: CGFloat = 3
    private let dotSpacing: CGFloat = 3
    private let columns = 2
    private let rows = 3

    private var dotColor: Color {
        isCompleted ? theme.textFaint : theme.checkBorder
    }

    var body: some View {
        VStack(spacing: dotSpacing) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: dotSpacing) {
                    ForEach(0..<columns, id: \.self) { _ in
                        Circle()
                            .fill(dotColor)
                            .frame(width: dotSize, height: dotSize)
                    }
                }
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityLabel("Reorder task")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 24) {
        DragHandleView(isCompleted: false)
        DragHandleView(isCompleted: true)
    }
    .padding()
    .withAppTheme()
}
