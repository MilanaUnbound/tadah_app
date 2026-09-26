import SwiftUI
import SwiftData

enum TaskRowLeadingAccessory {
    case checkbox
    case dragHandle
}

struct TaskRow: View {
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo
    @Environment(\.appTheme) private var theme

    let task: Task
    let onToggleComplete: () -> Void
    var isInteractive: Bool = true
    var checkboxIsInteractive: Bool = true
    var showsScheduleSubtitle: Bool = false
    var onRowTap: (() -> Void)? = nil
    var onDeleteUpcoming: (() -> Void)? = nil
    var onCategoryTap: (() -> Void)? = nil
    var trailingDateLabel: String? = nil
    var leadingAccessory: TaskRowLeadingAccessory = .checkbox
    var reorderDragGesture: AnyGesture<DragGesture.Value>? = nil

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
        isPendingDelete ? pendingDeleteBackground : theme.card
    }

    @State private var checkTrim: CGFloat = 0
    @State private var titleWidth: CGFloat = 0
    @State private var strikeProgress: CGFloat = 0
    @State private var isPressing = false

    private let pendingDeleteBackground = Color(red: 0xFF / 255, green: 0xF5 / 255, blue: 0xF5 / 255)
    private let pendingDeleteTitle = Color(red: 0xF8 / 255, green: 0x71 / 255, blue: 0x71 / 255)

    private var displayColor: Color {
        TaskCategoryDisplay.displayColor(for: task, projects: projects)
    }

    private var displayName: String {
        TaskCategoryDisplay.displayName(for: task, projects: projects)
    }

    private var badgeBackground: Color {
        task.isCompleted
            ? theme.btnBg
            : TaskCategoryDisplay.lightBackground(for: task, projects: projects)
    }

    private var titleFontWeight: SpaceGroteskWeight {
        return .medium
    }

    private var titleColor: Color {
        if isPendingDelete { return pendingDeleteTitle }
        if task.isCompleted { return theme.textFaint }
        return theme.text
    }

    private var shouldStrikethroughTitle: Bool {
        isPendingDelete || task.isCompleted
    }

    private var showAnimatedStrike: Bool {
        task.isCompleted && !isPendingDelete
    }

    private var shouldShowScheduleSubtitle: Bool {
        showsScheduleSubtitle && !task.isCompleted && task.scheduledDate != nil
    }

    var body: some View {
        HStack(spacing: 16) {
            rowTapTarget

            if let trailingDateLabel {
                Text(trailingDateLabel)
                    .font(.spaceGrotesk(.medium, size: 12))
                    .foregroundStyle(theme.textFaint)
            }

            categoryBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(cardBackground)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(task.isCompleted ? theme.border : displayColor)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 1)
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

    @ViewBuilder
    private var rowTapTarget: some View {
        let target = HStack(spacing: 16) {
            leadingView
            titleView
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if onRowTap != nil {
            target
                .contentShape(Rectangle())
                .onTapGesture {
                    guard rowIsInteractive else { return }
                    onRowTap?()
                }
        } else {
            target
        }
    }

    @ViewBuilder
    private var leadingView: some View {
        switch leadingAccessory {
        case .checkbox:
            checkbox
        case .dragHandle:
            dragHandleView
        }
    }

    @ViewBuilder
    private var dragHandleView: some View {
        DragHandleView(isCompleted: task.isCompleted)
            .modifier(OptionalHighPriorityDragGesture(gesture: reorderDragGesture))
    }

    private var checkbox: some View {
        Group {
            if rowIsInteractive && checkboxIsInteractive {
                Button {
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
                    .accessibilityHidden(checkboxIsInteractive == false)
            }
        }
        .frame(width: 24, height: 24)
    }

    private var checkboxContent: some View {
        ZStack {
            Circle()
                .fill(task.isCompleted ? displayColor : Color.clear)

            Circle()
                .stroke(task.isCompleted ? displayColor : theme.checkBorder, lineWidth: 2)

            CheckmarkShape()
                .trim(from: 0, to: checkTrim)
                .stroke(style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.white)
        }
    }

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                if task.showsRepeatIcon {
                    Image(systemName: "repeat")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? theme.textFaint : AppTheme.violet.opacity(0.85))
                        .accessibilityLabel("Recurring task")
                }

                Text(task.title)
                    .font(.spaceGrotesk(titleFontWeight, size: 14))
                    .foregroundStyle(titleColor)
                    .strikethrough(shouldStrikethroughTitle)
                    .lineLimit(1)
                    .background(
                        WidthReader(width: $titleWidth)
                    )
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(theme.textFaint)
                            .frame(width: titleWidth * strikeProgress, height: 1.5)
                            .opacity(showAnimatedStrike ? 1 : 0)
                    }
                    .animation(.easeOut(duration: 0.2), value: taskDeleteUndo.pendingDeleteTaskID)
            }

            if shouldShowScheduleSubtitle {
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.textMuted)

                    Text(DateHelpers.shortMonthDay(for: task.resolvedScheduledDate))
                        .font(.spaceGrotesk(.medium, size: 12))
                        .foregroundStyle(theme.textMuted)
                }
            }
        }
    }

    @ViewBuilder
    private var categoryBadge: some View {
        let badge = Text(displayName)
            .font(.spaceGrotesk(.semibold, size: 12))
            .foregroundStyle(task.isCompleted ? theme.textFaint : displayColor)
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

private struct OptionalHighPriorityDragGesture: ViewModifier {
    let gesture: AnyGesture<DragGesture.Value>?

    func body(content: Content) -> some View {
        if let gesture {
            content.highPriorityGesture(gesture)
        } else {
            content
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
