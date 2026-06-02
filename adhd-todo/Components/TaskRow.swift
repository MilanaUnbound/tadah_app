import SwiftUI
import SwiftData

struct TaskRow: View {
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo

    let task: Task
    let onToggleComplete: () -> Void
    var isInteractive: Bool = true
    var onDeleteUpcoming: (() -> Void)? = nil
    var onCategoryTap: (() -> Void)? = nil

    @Query(sort: \Project.name) private var projects: [Project]

    private var isPendingDelete: Bool {
        taskDeleteUndo.isPendingDelete(taskID: task.id)
    }

    private var rowIsInteractive: Bool {
        isInteractive && !isPendingDelete
    }

    private var rowOpacity: CGFloat {
        task.isCompleted && !isPendingDelete ? 0.6 : 1
    }

    private var cardBackground: Color {
        isPendingDelete ? pendingDeleteBackground : cardSurface
    }

    @State private var checkTrim: CGFloat = 0
    @State private var titleWidth: CGFloat = 0
    @State private var strikeProgress: CGFloat = 0
    @State private var isPressing = false

    private let borderGray = Color(red: 0xE5 / 255, green: 0xE7 / 255, blue: 0xEB / 255)
    private let checkboxGray = Color(red: 0xD1 / 255, green: 0xD5 / 255, blue: 0xDB / 255)
    private let disabledText = Color(red: 0x9C / 255, green: 0xA3 / 255, blue: 0xAF / 255)
    private let cardSurface = Color(.secondarySystemBackground)
    private let pendingDeleteBackground = Color(red: 0xFF / 255, green: 0xF5 / 255, blue: 0xF5 / 255)
    private let pendingDeleteTitle = Color(red: 0xF8 / 255, green: 0x71 / 255, blue: 0x71 / 255)
    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)

    private var displayColor: Color {
        TaskCategoryDisplay.displayColor(for: task, projects: projects)
    }

    private var displayName: String {
        TaskCategoryDisplay.displayName(for: task, projects: projects)
    }

    private var badgeBackground: Color {
        task.isCompleted
            ? Color(.tertiarySystemFill)
            : TaskCategoryDisplay.lightBackground(for: task, projects: projects)
    }

    private var titleFontWeight: SpaceGroteskWeight {
        if isPendingDelete || task.isCompleted { return .regular }
        return .medium
    }

    private var titleColor: Color {
        if isPendingDelete { return pendingDeleteTitle }
        if task.isCompleted { return disabledText }
        return Color.primary
    }

    private var shouldStrikethroughTitle: Bool {
        isPendingDelete || task.isCompleted
    }

    private var showAnimatedStrike: Bool {
        task.isCompleted && !isPendingDelete
    }

    var body: some View {
        HStack(spacing: 16) {
            checkbox

            titleView

            Spacer(minLength: 0)

            categoryBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(cardBackground)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(task.isCompleted ? borderGray : displayColor)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        .opacity(rowOpacity)
        .animation(.easeOut(duration: 0.2), value: taskDeleteUndo.pendingDeleteTaskID)
        .allowsHitTesting(rowIsInteractive)
        .onAppear {
            syncAnimatedState(animated: false)
        }
        .onChange(of: task.isCompleted) { _, _ in
            syncAnimatedState(animated: true)
        }
        .contextMenu {
            if rowIsInteractive, task.showsRepeatIcon, let onDeleteUpcoming {
                Button("Delete all upcoming", role: .destructive) {
                    onDeleteUpcoming()
                }
            }
        }
    }

    private var checkbox: some View {
        Group {
            if rowIsInteractive {
                Button {
                    print("Toggle task:", task.id, "completed:", !task.isCompleted)

                    withAnimation(.easeOut(duration: 0.22)) {
                        onToggleComplete()
                    }
                } label: {
                    checkboxContent
                        .scaleEffect(isPressing ? 0.72 : 1)
                        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressing)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if isPressing == false { isPressing = true }
                        }
                        .onEnded { _ in
                            isPressing = false
                        }
                )
                .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
            } else {
                checkboxContent
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 24, height: 24)
    }

    private var checkboxContent: some View {
        ZStack {
            Circle()
                .fill(task.isCompleted ? displayColor : Color.clear)

            Circle()
                .stroke(task.isCompleted ? displayColor : checkboxGray, lineWidth: 2)

            CheckmarkShape()
                .trim(from: 0, to: checkTrim)
                .stroke(style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.white)
        }
    }

    private var titleView: some View {
        HStack(spacing: 6) {
            if task.showsRepeatIcon {
                Image(systemName: "repeat")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(task.isCompleted ? disabledText : violet.opacity(0.85))
                    .accessibilityLabel("Recurring task")
            }

            Text(task.title)
                .font(.spaceGrotesk(titleFontWeight, size: 14))
                .foregroundStyle(titleColor)
                .strikethrough(shouldStrikethroughTitle)
                .background(
                    WidthReader(width: $titleWidth)
                )
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(disabledText)
                        .frame(width: titleWidth * strikeProgress, height: 1.5)
                        .opacity(showAnimatedStrike ? 1 : 0)
                }
                .animation(.easeOut(duration: 0.2), value: taskDeleteUndo.pendingDeleteTaskID)
        }
    }

    @ViewBuilder
    private var categoryBadge: some View {
        let badge = Text(displayName)
            .font(.spaceGrotesk(.semibold, size: 12))
            .foregroundStyle(task.isCompleted ? disabledText : displayColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(badgeBackground)
            .clipShape(Capsule())

        if let onCategoryTap, !isPendingDelete {
            Button(action: onCategoryTap) {
                badge
            }
            .buttonStyle(.plain)
        } else {
            badge
        }
    }

    private func syncAnimatedState(animated: Bool) {
        let updates = {
            checkTrim = task.isCompleted ? 1 : 0
            strikeProgress = task.isCompleted ? 1 : 0
        }

        if animated {
            withAnimation(.easeOut(duration: 0.22)) {
                checkTrim = task.isCompleted ? 1 : 0
            }
            withAnimation(.easeOut(duration: 0.25)) {
                strikeProgress = task.isCompleted ? 1 : 0
            }
        } else {
            updates()
        }
    }
}

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()

        let w = rect.width
        let h = rect.height

        p.move(to: CGPoint(x: rect.minX + w * 0.28, y: rect.minY + h * 0.55))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.44, y: rect.minY + h * 0.70))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.74, y: rect.minY + h * 0.36))

        return p
    }
}

private struct WidthReader: View {
    @Binding var width: CGFloat

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { width = geo.size.width }
                .onChange(of: geo.size.width) { _, newValue in
                    width = newValue
                }
        }
    }
}
