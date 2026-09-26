import SwiftUI

enum SwipeRightAction {
    case complete
    case custom(icon: String, handler: () -> Void)
    case disabled
}

struct SwipeableTaskRow<Content: View>: View {
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo
    @Environment(\.reorderDragActiveID) private var reorderDragActiveID

    let taskID: UUID
    let categoryColor: Color
    let isCompleted: Bool
    let onToggleComplete: () -> Void
    let onDelete: () -> Void
    var swipeRightAction: SwipeRightAction = .complete
    @ViewBuilder let content: () -> Content

    private var isPendingDelete: Bool {
        taskDeleteUndo.isPendingDelete(taskID: taskID)
    }

    @State private var offsetX: CGFloat = 0
    @State private var isDragging = false
    @State private var dragAxis: SwipeDragAxis?
    @State private var suppressContentTaps = false

    private enum SwipeDragAxis {
        case horizontal
        case vertical
    }

    private let axisLockDistance: CGFloat = 12
    private let threshold: CGFloat = 72
    private let maxOffset: CGFloat = 110
    private let revealThreshold: CGFloat = 8

    private let deleteRed = Color(red: 0xEF / 255, green: 0x44 / 255, blue: 0x44 / 255)

    private var showDeleteBackground: Bool { offsetX < -revealThreshold }
    private var showRightSwipeBackground: Bool {
        guard allowsPositiveSwipe else { return false }
        return offsetX > revealThreshold
    }
    private var isSwipeEnabled: Bool { reorderDragActiveID == nil && isPendingDelete == false }

    private var allowsPositiveSwipe: Bool {
        switch swipeRightAction {
        case .complete:
            return !isCompleted
        case .custom:
            return true
        case .disabled:
            return false
        }
    }

    private var rightSwipeIcon: String {
        switch swipeRightAction {
        case .complete:
            return isCompleted ? "arrow.uturn.backward" : "checkmark"
        case .custom(let icon, _):
            return icon
        case .disabled:
            return "checkmark"
        }
    }

    var body: some View {
        ZStack {
            actionBackground

            content()
                .offset(x: offsetX)
                .allowsHitTesting(!suppressContentTaps)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(isDragging ? nil : .easeOut(duration: 0.25), value: offsetX)
        .simultaneousGesture(isSwipeEnabled ? swipeGesture : nil)
    }

    @ViewBuilder
    private var actionBackground: some View {
        Group {
            if showDeleteBackground {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(deleteRed)
                    .overlay(alignment: .trailing) {
                        Image(systemName: "trash")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.trailing, 20)
                    }
            } else if showRightSwipeBackground {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(categoryColor)
                    .overlay(alignment: .leading) {
                        Image(systemName: rightSwipeIcon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.leading, 20)
                    }
            } else {
                Color.clear
            }
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height

                if dragAxis == nil {
                    let absDx = abs(dx)
                    let absDy = abs(dy)
                    guard max(absDx, absDy) >= axisLockDistance else { return }
                    dragAxis = absDx > absDy ? .horizontal : .vertical
                    if dragAxis == .horizontal {
                        suppressContentTaps = true
                    }
                }

                guard dragAxis == .horizontal else { return }

                isDragging = true
                if dx > 0 && !allowsPositiveSwipe { return }
                offsetX = min(maxOffset, max(-maxOffset, dx))
            }
            .onEnded { _ in
                defer {
                    isDragging = false
                    dragAxis = nil
                    releaseContentTapsAfterSwipe()
                }

                guard dragAxis == .horizontal else { return }

                if offsetX < -threshold {
                    withAnimation(.easeOut(duration: 0.2)) {
                        offsetX = 0
                    }
                    onDelete()
                } else if offsetX > threshold {
                    handleRightSwipe()
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        offsetX = 0
                    }
                }
            }
    }

    private func handleRightSwipe() {
        switch swipeRightAction {
        case .complete:
            guard !isCompleted else { return }
            withAnimation(.easeOut(duration: 0.22)) {
                onToggleComplete()
                offsetX = 0
            }
        case .custom(_, let handler):
            withAnimation(.easeOut(duration: 0.2)) {
                offsetX = 0
            }
            handler()
        case .disabled:
            withAnimation(.easeOut(duration: 0.2)) {
                offsetX = 0
            }
        }
    }

    private func releaseContentTapsAfterSwipe() {
        guard suppressContentTaps else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            suppressContentTaps = false
        }
    }
}

#Preview("Incomplete — swipe right to complete") {
    struct PreviewWrapper: View {
        @State private var completed = false

        var body: some View {
            SwipeableTaskRow(
                taskID: UUID(),
                categoryColor: Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255),
                isCompleted: completed,
                onToggleComplete: { completed.toggle() },
                onDelete: {}
            ) {
                previewCard(title: "Sample task", completed: completed)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("Complete — swipe right to undo") {
    struct PreviewWrapper: View {
        @State private var completed = true

        var body: some View {
            SwipeableTaskRow(
                taskID: UUID(),
                categoryColor: Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255),
                isCompleted: completed,
                onToggleComplete: { completed.toggle() },
                onDelete: {}
            ) {
                previewCard(title: "Done task", completed: completed)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

@ViewBuilder
private func previewCard(title: String, completed: Bool) -> some View {
    HStack {
        Image(systemName: completed ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(completed ? Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255) : .gray)
        Text(title)
            .font(.spaceGrotesk(.medium, size: 14))
            .strikethrough(completed)
        Spacer()
    }
    .padding(16)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
}
