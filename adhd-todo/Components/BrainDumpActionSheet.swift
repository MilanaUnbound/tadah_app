import SwiftUI

struct BrainDumpActionSheet: View {
    let title: String
    let categoryRaw: String
    let categoryName: String
    let categoryColor: Color
    let scheduleHint: String
    let projects: [Project]
    @Binding var showTagPicker: Bool
    let onSchedule: () -> Void
    let onSelectCategory: (CategorySelection) -> Void
    let onClearCategory: () -> Void
    let onMarkDone: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var dragDismiss = BottomSheetDragDismissState()

    private var hasCategory: Bool { categoryRaw.isEmpty == false }

    private var options: [CategoryPickerOption] {
        CategoryPickerOption.allOptions(projects: projects)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(dragDismiss.backdropOpacity(base: 0.4))
                .ignoresSafeArea()
                .onTapGesture {
                    dragDismiss.dismissAnimated(onDismiss: onClose)
                }

            sheetPanel
                .bottomSheetDragDismiss(state: dragDismiss, onDismiss: onClose)
        }
    }

    private var sheetPanel: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(theme.border)
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 4)

            headerRow

            VStack(spacing: 8) {
                scheduleRow
                categoryRow

                if showTagPicker {
                    categoryChips
                }

                markDoneDeleteRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: 390)
        .frame(maxWidth: .infinity)
        .background(theme.sheet)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24
            )
        )
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.spaceGrotesk(.semibold, size: 15))
                .foregroundStyle(theme.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                dragDismiss.dismissAnimated(onDismiss: onClose)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.textSub)
                    .frame(width: 30, height: 30)
                    .background(theme.btnBg, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var scheduleRow: some View {
        Button(action: onSchedule) {
            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppTheme.exportBlue)
                    .frame(width: 34, height: 34)
                    .background(
                        AppTheme.exportBlue.opacity(0.13),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text("Schedule")
                        .font(.spaceGrotesk(.medium, size: 15))
                        .foregroundStyle(theme.text)
                    Text(scheduleHint)
                        .font(.spaceGrotesk(.regular, size: 12))
                        .foregroundStyle(theme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(theme.btnBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var categoryRow: some View {
        Button {
            showTagPicker.toggle()
        } label: {
            HStack(spacing: 14) {
                Text("🏷")
                    .font(.system(size: 17))
                    .frame(width: 34, height: 34)
                    .background(
                        Color(red: 0xF5 / 255, green: 0x9E / 255, blue: 0x0B / 255).opacity(0.13),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text("Category")
                        .font(.spaceGrotesk(.medium, size: 15))
                        .foregroundStyle(theme.text)
                    Text(hasCategory ? categoryName : "None assigned")
                        .font(.spaceGrotesk(.regular, size: 12))
                        .foregroundStyle(theme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if hasCategory {
                    Text(categoryName)
                        .font(.spaceGrotesk(.medium, size: 12))
                        .foregroundStyle(categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(categoryColor.opacity(0.13), in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(theme.btnBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var categoryChips: some View {
        FlowCategoryChips(
            options: options,
            currentCategoryRaw: categoryRaw,
            hasCategory: hasCategory,
            onClear: onClearCategory,
            onSelect: onSelectCategory
        )
    }

    private var markDoneDeleteRow: some View {
        HStack(spacing: 8) {
            Button(action: onMarkDone) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                    Text("Mark done")
                        .font(.spaceGrotesk(.semibold, size: 14))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    AppTheme.importGreen,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppTheme.deleteRed)
                    .frame(width: 50, height: 46)
                    .background(
                        AppTheme.deleteRed.opacity(0.13),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }
}

private struct FlowCategoryChips: View {
    let options: [CategoryPickerOption]
    let currentCategoryRaw: String
    let hasCategory: Bool
    let onClear: () -> Void
    let onSelect: (CategorySelection) -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 72), spacing: 6)],
            alignment: .leading,
            spacing: 6
        ) {
            if hasCategory {
                Button(action: onClear) {
                    Text("None")
                        .font(.spaceGrotesk(.medium, size: 12))
                        .foregroundStyle(theme.textSub)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(theme.progressBg, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            ForEach(options) { option in
                CategoryChipButton(
                    option: option,
                    isSelected: option.categoryRaw == currentCategoryRaw,
                    onSelect: onSelect
                )
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CategoryChipButton: View {
    let option: CategoryPickerOption
    let isSelected: Bool
    let onSelect: (CategorySelection) -> Void

    var body: some View {
        Button {
            onSelect(option.categorySelection)
        } label: {
            Text(option.displayName)
                .font(.spaceGrotesk(.medium, size: 12))
                .foregroundStyle(isSelected ? Color.white : option.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(
                    isSelected ? option.color : option.color.opacity(0.13),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}
