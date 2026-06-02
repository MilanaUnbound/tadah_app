import SwiftUI

struct SwipeableTaskRow<Content: View>: View {
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo

    let taskID: UUID
    let categoryColor: Color
    let isCompleted: Bool
    let onToggleComplete: () -> Void
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    private var isPendingDelete: Bool {
        taskDeleteUndo.isPendingDelete(taskID: taskID)
    }

    @State private var offsetX: CGFloat = 0
    @State private var isDragging = false

    private let threshold: CGFloat = 72
    private let maxOffset: CGFloat = 110
    private let revealThreshold: CGFloat = 8

    private let deleteRed = Color(red: 0xEF / 255, green: 0x44 / 255, blue: 0x44 / 255)

    private var showDeleteBackground: Bool { offsetX < -revealThreshold }
    private var showCompleteBackground: Bool { offsetX > revealThreshold }

    var body: some View {
        ZStack {
            actionBackground

            content()
                .offset(x: offsetX)
                .gesture(isPendingDelete ? nil : swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(isDragging ? nil : .easeOut(duration: 0.25), value: offsetX)
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
            } else if showCompleteBackground {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(categoryColor)
                    .overlay(alignment: .leading) {
                        Image(systemName: isCompleted ? "arrow.uturn.backward" : "checkmark")
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
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height

                guard abs(dx) > abs(dy) else { return }

                isDragging = true
                offsetX = min(maxOffset, max(-maxOffset, dx))
            }
            .onEnded { _ in
                isDragging = false

                if offsetX < -threshold {
                    offsetX = 0
                    onDelete()
                } else if offsetX > threshold {
                    withAnimation(.easeOut(duration: 0.22)) {
                        onToggleComplete()
                    }
                    offsetX = 0
                } else {
                    offsetX = 0
                }
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
