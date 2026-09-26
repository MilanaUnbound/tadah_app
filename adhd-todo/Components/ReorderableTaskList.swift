import SwiftUI
import SwiftData

struct ReorderDragActiveKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

extension EnvironmentValues {
    var reorderDragActiveID: UUID? {
        get { self[ReorderDragActiveKey.self] }
        set { self[ReorderDragActiveKey.self] = newValue }
    }
}

private struct RowCenterPreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGFloat] = [:]

    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct ReorderableTaskList<RowContent: View>: View {
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo

    let tasks: [Task]
    let onMove: (UUID, Int) -> Void
    @ViewBuilder let rowContent: (Task, AnyGesture<DragGesture.Value>?) -> RowContent

    @State private var draggingID: UUID?
    @State private var dragOffset: CGFloat = 0
    @State private var rowCenters: [UUID: CGFloat] = [:]
    @State private var dragAxis: ReorderDragAxis?

    private enum ReorderDragAxis {
        case vertical
        case horizontal
    }

    private let axisLockDistance: CGFloat = 12

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                rowContent(task, dragGesture(for: task, at: index))
                    .offset(y: rowOffset(for: task, at: index))
                    .zIndex(draggingID == task.id ? 1 : 0)
                    .background(rowCenterReader(for: task))
            }
        }
        .coordinateSpace(name: "reorderList")
        .onPreferenceChange(RowCenterPreferenceKey.self) { rowCenters = $0 }
        .environment(\.reorderDragActiveID, draggingID)
        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.82), value: dragOffset)
        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.82), value: draggingID)
    }

    @ViewBuilder
    private func rowCenterReader(for task: Task) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: RowCenterPreferenceKey.self,
                value: [task.id: geo.frame(in: .named("reorderList")).midY]
            )
        }
    }

    private func rowOffset(for task: Task, at index: Int) -> CGFloat {
        guard draggingID == task.id else { return 0 }
        return dragOffset
    }

    private func dragGesture(for task: Task, at index: Int) -> AnyGesture<DragGesture.Value>? {
        guard taskDeleteUndo.isPendingDelete(taskID: task.id) == false else { return nil }

        return AnyGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height

                    if dragAxis == nil {
                        let absDx = abs(dx)
                        let absDy = abs(dy)
                        guard max(absDx, absDy) >= axisLockDistance else { return }
                        dragAxis = absDy > absDx ? .vertical : .horizontal
                    }

                    guard dragAxis == .vertical else { return }

                    if draggingID == nil {
                        draggingID = task.id
                    }
                    guard draggingID == task.id else { return }
                    dragOffset = dy
                }
                .onEnded { _ in
                    defer {
                        dragAxis = nil
                    }

                    guard dragAxis == .vertical, draggingID == task.id else {
                        draggingID = nil
                        dragOffset = 0
                        return
                    }

                    let targetIndex = targetIndex(for: task, from: index)
                    if targetIndex != index {
                        withAnimation(.easeOut(duration: 0.2)) {
                            onMove(task.id, targetIndex)
                        }
                    }

                    draggingID = nil
                    dragOffset = 0
                }
        )
    }

    private func targetIndex(for task: Task, from sourceIndex: Int) -> Int {
        guard let draggedCenter = rowCenters[task.id] else { return sourceIndex }
        let currentY = draggedCenter + dragOffset

        var target = sourceIndex

        for (index, candidate) in tasks.enumerated() where candidate.id != task.id {
            guard let center = rowCenters[candidate.id] else { continue }

            if index < sourceIndex, currentY < center {
                target = index
                break
            }

            if index > sourceIndex, currentY > center {
                target = index
            }
        }

        return target
    }
}
