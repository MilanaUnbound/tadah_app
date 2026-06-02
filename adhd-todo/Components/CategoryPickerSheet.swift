import SwiftUI

struct CategoryPickerSheet: View {
    let projects: [Project]
    let context: CategoryPickerContext
    let onSelect: (CategorySelection) -> Void
    let onClose: () -> Void

    private let mutedHeader = Color(red: 0xAA / 255, green: 0xAA / 255, blue: 0xAA / 255)
    private let rowSeparator = Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF5 / 255)
    private let titleColor = Color(red: 0x22 / 255, green: 0x22 / 255, blue: 0x22 / 255)
    private let currentLabel = Color(red: 0xAA / 255, green: 0xAA / 255, blue: 0xAA / 255)

    private var options: [CategoryPickerOption] {
        CategoryPickerOption.allOptions(projects: projects)
    }

    private var headerTitle: String {
        context.isBulk ? "Reassign all tasks to" : "Change category"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(alignment: .leading, spacing: 0) {
                Text(headerTitle)
                    .font(.spaceGrotesk(.medium, size: 12))
                    .foregroundStyle(mutedHeader)
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .padding(.bottom, 16)

                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    if index > 0 {
                        Divider()
                            .background(rowSeparator)
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
                                .foregroundStyle(titleColor)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if option.categoryRaw == context.currentCategoryRaw {
                                Text("Current")
                                    .font(.spaceGrotesk(.medium, size: 12))
                                    .foregroundStyle(currentLabel)
                            }
                        }
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 44)
            .frame(maxWidth: 390)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    topTrailingRadius: 20
                )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 24, x: 0, y: -4)
        }
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
}
