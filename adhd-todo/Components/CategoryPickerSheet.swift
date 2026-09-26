import SwiftUI

struct CategoryPickerSheet: View {
    let projects: [Project]
    let context: CategoryPickerContext
    let onSelect: (CategorySelection) -> Void
    let onClose: () -> Void

    @Environment(\.appTheme) private var theme

    @State private var dragDismiss = BottomSheetDragDismissState()

    private var options: [CategoryPickerOption] {
        CategoryPickerOption.allOptions(projects: projects)
    }

    private var headerTitle: String {
        context.isBulk ? "Reassign all tasks to" : "Change category"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(dragDismiss.backdropOpacity(base: 0.25))
                .ignoresSafeArea()
                .onTapGesture {
                    dragDismiss.dismissAnimated(onDismiss: onClose)
                }

            sheetPanel
                .bottomSheetDragDismiss(state: dragDismiss, onDismiss: onClose)
        }
    }

    private var sheetPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(theme.border)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 12)

            Text(headerTitle)
                .font(.spaceGrotesk(.medium, size: 12))
                .foregroundStyle(theme.textMuted)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.bottom, 16)

            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                if index > 0 {
                    Divider()
                        .background(theme.border)
                }

                Button {
                    onSelect(option.categorySelection)
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(option.color)
                            .frame(width: 10, height: 10)

                        Text(option.displayName)
                            .font(.spaceGrotesk(.medium, size: 15))
                            .foregroundStyle(theme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if option.categoryRaw == context.currentCategoryRaw {
                            Text("Current")
                                .font(.spaceGrotesk(.medium, size: 12))
                                .foregroundStyle(theme.textMuted)
                        }
                    }
                    .padding(.vertical, 13)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 44)
        .frame(maxWidth: 390)
        .frame(maxWidth: .infinity)
        .background(theme.sheet)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                topTrailingRadius: 20
            )
        )
    }
}

#Preview {
    CategoryPickerSheet(
        projects: [],
        context: CategoryPickerContext(
            target: .task(UUID()),
            currentCategoryRaw: Category.work.rawValue
        ),
        onSelect: { _ in },
        onClose: {}
    )
    .withAppTheme()
}
