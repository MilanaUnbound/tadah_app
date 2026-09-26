import SwiftUI

struct UpcomingSection: View {
    @Environment(CategoryPickerController.self) private var categoryPicker
    @Environment(\.appTheme) private var theme

    let tasks: [Task]
    let projects: [Project]
    let onScheduleTap: (_ task: Task) -> Void
    let onDelete: (_ task: Task) -> Void
    let onRecurringSwipeRight: (_ instances: [Task]) -> Void

    @State private var isOpen = false
    @State private var itemOrder: [String] = UpcomingOrderStore.load()

    private struct UpcomingItem: Identifiable {
        enum Kind {
            case single(Task)
            case recurring(seriesId: UUID, tasks: [Task])
        }

        let id: String
        let kind: Kind

        var representative: Task {
            switch kind {
            case .single(let task):
                return task
            case .recurring(_, let tasks):
                return tasks.first(where: { $0.isCompleted == false })
                    ?? tasks.min(by: { $0.resolvedScheduledDate < $1.resolvedScheduledDate })
                    ?? tasks[0]
            }
        }

        var tasks: [Task] {
            switch kind {
            case .single(let task):
                return [task]
            case .recurring(_, let tasks):
                return tasks
            }
        }

        var dateLabel: String {
            let keys = tasks.map(\.dateKey)
            guard let minKey = keys.min(), let maxKey = keys.max() else {
                return DateHelpers.chipLabel(forKey: representative.dateKey)
            }
            if minKey == maxKey {
                return DateHelpers.chipLabel(forKey: minKey)
            }
            return "\(DateHelpers.chipLabel(forKey: minKey))–\(DateHelpers.chipLabel(forKey: maxKey))"
        }
    }

    private var rawItems: [UpcomingItem] {
        let groups = Dictionary(grouping: tasks, by: { $0.recurrenceSeriesId })

        var out: [UpcomingItem] = []
        out.reserveCapacity(tasks.count)

        for (seriesId, bucket) in groups {
            if let seriesId {
                let sorted = bucket.sorted(by: { $0.resolvedScheduledDate < $1.resolvedScheduledDate })
                out.append(UpcomingItem(id: "series-\(seriesId.uuidString)", kind: .recurring(seriesId: seriesId, tasks: sorted)))
            } else {
                for task in bucket {
                    out.append(UpcomingItem(id: "task-\(task.id.uuidString)", kind: .single(task)))
                }
            }
        }

        return out
    }

    private var itemIDSignature: [String] {
        rawItems.map(\.id).sorted()
    }

    private var items: [UpcomingItem] {
        let byID = Dictionary(uniqueKeysWithValues: rawItems.map { ($0.id, $0) })
        return itemOrder.compactMap { byID[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    isOpen.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Upcoming · \(items.count)")
                        .font(.spaceGrotesk(.medium, size: 12))
                        .foregroundStyle(theme.textMuted)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.textFaint)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                        .animation(.easeOut(duration: 0.2), value: isOpen)

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isOpen {
                ReorderableUpcomingList(
                    items: items,
                    onMove: moveItem
                ) { item, dragGesture in
                    upcomingRow(for: item, reorderDragGesture: dragGesture)
                }
            }
        }
        .onAppear {
            syncItemOrder()
        }
        .onChange(of: itemIDSignature) { _, _ in
            syncItemOrder()
        }
    }

    private struct ReorderableUpcomingList<RowContent: View>: View {
        @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo

        let items: [UpcomingItem]
        let onMove: (String, Int) -> Void
        @ViewBuilder let rowContent: (UpcomingItem, AnyGesture<DragGesture.Value>?) -> RowContent

        @State private var draggingRepresentativeID: UUID?
        @State private var dragOffset: CGFloat = 0
        @State private var rowCenters: [UUID: CGFloat] = [:]
        @State private var dragAxis: ReorderDragAxis?

        private enum ReorderDragAxis {
            case vertical
            case horizontal
        }

        private let axisLockDistance: CGFloat = 12

        var body: some View {
            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    rowContent(item, dragGesture(for: item, at: index))
                        .offset(y: rowOffset(for: item))
                        .zIndex(draggingRepresentativeID == item.representative.id ? 1 : 0)
                        .background(rowCenterReader(for: item))
                }
            }
            .coordinateSpace(name: "upcomingReorderList")
            .onPreferenceChange(UpcomingRowCenterPreferenceKey.self) { rowCenters = $0 }
            .environment(\.reorderDragActiveID, draggingRepresentativeID)
            .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.82), value: dragOffset)
            .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.82), value: draggingRepresentativeID)
        }

        @ViewBuilder
        private func rowCenterReader(for item: UpcomingItem) -> some View {
            GeometryReader { geo in
                Color.clear.preference(
                    key: UpcomingRowCenterPreferenceKey.self,
                    value: [item.representative.id: geo.frame(in: .named("upcomingReorderList")).midY]
                )
            }
        }

        private func rowOffset(for item: UpcomingItem) -> CGFloat {
            guard draggingRepresentativeID == item.representative.id else { return 0 }
            return dragOffset
        }

        private func dragGesture(for item: UpcomingItem, at index: Int) -> AnyGesture<DragGesture.Value>? {
            guard taskDeleteUndo.isPendingDelete(taskID: item.representative.id) == false else { return nil }

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

                        if draggingRepresentativeID == nil {
                            draggingRepresentativeID = item.representative.id
                        }
                        guard draggingRepresentativeID == item.representative.id else { return }
                        dragOffset = dy
                    }
                    .onEnded { _ in
                        defer {
                            dragAxis = nil
                        }

                        guard dragAxis == .vertical, draggingRepresentativeID == item.representative.id else {
                            draggingRepresentativeID = nil
                            dragOffset = 0
                            return
                        }

                        let targetIndex = targetIndex(for: item, from: index)
                        if targetIndex != index {
                            withAnimation(.easeOut(duration: 0.2)) {
                                onMove(item.id, targetIndex)
                            }
                        }

                        draggingRepresentativeID = nil
                        dragOffset = 0
                    }
            )
        }

        private func targetIndex(for item: UpcomingItem, from sourceIndex: Int) -> Int {
            guard let draggedCenter = rowCenters[item.representative.id] else { return sourceIndex }
            let currentY = draggedCenter + dragOffset

            var target = sourceIndex

            for (index, candidate) in items.enumerated() where candidate.id != item.id {
                guard let center = rowCenters[candidate.representative.id] else { continue }

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

    private func syncItemOrder() {
        let byID = Dictionary(uniqueKeysWithValues: rawItems.map { ($0.id, $0) })
        let defaultNewOrder: (String, String) -> Bool = { lhs, rhs in
            guard let left = byID[lhs], let right = byID[rhs] else { return lhs < rhs }
            return left.representative.resolvedScheduledDate < right.representative.resolvedScheduledDate
        }

        itemOrder = UpcomingOrderStore.merge(
            itemIDs: rawItems.map(\.id),
            defaultOrderForNew: defaultNewOrder,
            savedOrder: itemOrder
        )
        UpcomingOrderStore.save(itemOrder)
    }

    private func moveItem(itemID: String, toIndex: Int) {
        UpcomingOrderStore.move(itemID: itemID, toIndex: toIndex, in: &itemOrder)
        UpcomingOrderStore.save(itemOrder)
    }

    @ViewBuilder
    private func upcomingRow(
        for item: UpcomingItem,
        reorderDragGesture: AnyGesture<DragGesture.Value>?
    ) -> some View {
        let swipeRightAction: SwipeRightAction = {
            switch item.kind {
            case .single:
                return .complete
            case .recurring:
                return .custom(icon: "calendar") {
                    onRecurringSwipeRight(item.tasks)
                }
            }
        }()

        let deleteUpcomingAction: (() -> Void)? = {
            if case .recurring = item.kind {
                return { onDelete(item.representative) }
            }
            return nil
        }()

        SwipeableTaskRow(
            taskID: item.representative.id,
            categoryColor: TaskCategoryDisplay.displayColor(
                for: item.representative,
                projects: projects
            ),
            isCompleted: item.representative.isCompleted,
            onToggleComplete: {
                TaskCompletionHelper.toggle(item.representative)
            },
            onDelete: {
                onDelete(item.representative)
            },
            swipeRightAction: swipeRightAction
        ) {
            TaskRow(
                task: item.representative,
                onToggleComplete: {
                    TaskCompletionHelper.toggle(item.representative)
                },
                checkboxIsInteractive: false,
                onRowTap: { onScheduleTap(item.representative) },
                onDeleteUpcoming: deleteUpcomingAction,
                onCategoryTap: {
                    categoryPicker.present(task: item.representative)
                },
                trailingDateLabel: item.dateLabel,
                leadingAccessory: .dragHandle,
                reorderDragGesture: reorderDragGesture
            )
        }
    }
}

private struct UpcomingRowCenterPreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGFloat] = [:]

    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

#Preview {
    UpcomingSection(
        tasks: [
            Task(title: "Book dentist", category: .health, dateKey: DateHelpers.todayKey())
        ],
        projects: [],
        onScheduleTap: { _ in },
        onDelete: { _ in },
        onRecurringSwipeRight: { _ in }
    )
    .padding()
    .environment(CategoryPickerController())
    .environment(TaskDeleteUndoController())
    .modelContainer(for: [Task.self, Project.self], inMemory: true)
}
