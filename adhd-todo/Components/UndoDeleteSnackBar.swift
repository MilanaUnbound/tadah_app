import SwiftUI
import SwiftData

struct UndoDeleteSnackBar: View {
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo
    @Environment(\.modelContext) private var modelContext

    private let barBackground = Color(red: 0x1C / 255, green: 0x19 / 255, blue: 0x29 / 255)
    private let messageColor = Color.white.opacity(0.75)
    private let undoColor = Color(red: 0xA7 / 255, green: 0x8B / 255, blue: 0xFA / 255)

    var body: some View {
        if taskDeleteUndo.pendingUndo != nil {
            HStack(spacing: 20) {
                Text("\"\(taskDeleteUndo.displayTitle)\" removed")
                    .font(.spaceGrotesk(.medium, size: 14))
                    .foregroundStyle(messageColor)
                    .lineLimit(1)

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        taskDeleteUndo.undo(in: modelContext)
                    }
                } label: {
                    Text("Undo")
                        .font(.spaceGrotesk(.semibold, size: 14))
                        .foregroundStyle(undoColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(barBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var controller = TaskDeleteUndoController()

        var body: some View {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                UndoDeleteSnackBar()
                    .padding(.bottom, 36)
            }
            .environment(controller)
            .onAppear {
                controller.pendingUndo = TaskUndoSnapshot(
                    task: Task(
                        title: "Buy groceries",
                        category: .health,
                        dateKey: DateHelpers.todayKey()
                    )
                )
            }
        }
    }

    return PreviewWrapper()
        .modelContainer(for: [Task.self], inMemory: true)
}
