import SwiftUI
import SwiftData

struct UndoDeleteSnackBar: View {
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme

    var body: some View {
        if taskDeleteUndo.showsUndoSnackBar {
            HStack(spacing: 20) {
                Text("\"\(taskDeleteUndo.displayTitle)\" removed")
                    .font(.spaceGrotesk(.medium, size: 14))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        taskDeleteUndo.undo(in: modelContext)
                    }
                } label: {
                    Text("Undo")
                        .font(.spaceGrotesk(.semibold, size: 14))
                        .foregroundStyle(AppTheme.violet)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: theme.cardShadowColor, radius: 12, x: 0, y: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var controller = TaskDeleteUndoController()

        var body: some View {
            ZStack(alignment: .bottom) {
                AppTheme.light.bg
                    .ignoresSafeArea()

                UndoDeleteSnackBar()
                    .padding(.bottom, 36)
            }
            .withAppTheme()
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
