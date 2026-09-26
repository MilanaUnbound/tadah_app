import SwiftUI

@Observable
final class BottomSheetDragDismissState {
    var dragOffset: CGFloat = 0
    var presentedPanelOffset: CGFloat = 0
    var backdropVisible: Double = 0
    private(set) var isDismissing = false

    private let dismissThreshold: CGFloat = 80
    private let predictedDismissThreshold: CGFloat = 120
    private let minimumDragDistance: CGFloat = 10
    private let dismissTravelDistance: CGFloat = 500
    private let dismissAnimationDuration: TimeInterval = 0.22

    var panelOffset: CGFloat {
        presentedPanelOffset + dragOffset
    }

    func backdropOpacity(base: Double) -> Double {
        backdropVisible * base * (1 - min(dragOffset / 200, 0.5))
    }

    func presentPanel() {
        isDismissing = false
        dragOffset = 0
        presentedPanelOffset = dismissTravelDistance
        backdropVisible = 0

        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
            presentedPanelOffset = 0
            backdropVisible = 1
        }
    }

    func dismissAnimated(onDismiss: @escaping () -> Void) {
        guard isDismissing == false else { return }
        isDismissing = true

        withAnimation(.easeOut(duration: dismissAnimationDuration)) {
            presentedPanelOffset = dismissTravelDistance
            dragOffset = 0
            backdropVisible = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dismissAnimationDuration) {
            Self.dismissWithoutAnimation(onDismiss)
        }
    }

    func dragGesture(onDismiss: @escaping () -> Void) -> some Gesture {
        DragGesture(minimumDistance: minimumDragDistance)
            .onChanged { [self] value in
                guard isDismissing == false else { return }

                let dx = value.translation.width
                let dy = value.translation.height

                guard abs(dy) > abs(dx) else { return }

                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    dragOffset = max(0, dy)
                }
            }
            .onEnded { [self] value in
                guard isDismissing == false else { return }

                let shouldDismiss =
                    dragOffset > dismissThreshold
                    || value.predictedEndTranslation.height > predictedDismissThreshold

                if shouldDismiss {
                    dismissAnimated(onDismiss: onDismiss)
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        dragOffset = 0
                    }
                }
            }
    }

    static func dismissWithoutAnimation(_ action: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, action)
    }
}

extension View {
    func bottomSheetPanel(state: BottomSheetDragDismissState) -> some View {
        offset(y: state.panelOffset)
            .onAppear {
                state.presentPanel()
            }
    }

    func bottomSheetDragDismiss(
        state: BottomSheetDragDismissState,
        onDismiss: @escaping () -> Void
    ) -> some View {
        offset(y: state.panelOffset)
            .gesture(state.dragGesture(onDismiss: onDismiss))
            .onAppear {
                state.presentPanel()
            }
    }
}
