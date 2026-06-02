import SwiftUI

struct CategoryPill: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            Text(category.displayName)
                .font(.spaceGrotesk(.semibold, size: 12))
                .foregroundStyle(isSelected ? Color.white : category.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? category.color : category.lightColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            CategoryPill(category: .work, isSelected: true, onTap: {})
            CategoryPill(category: .work, isSelected: false, onTap: {})
        }
        HStack {
            CategoryPill(category: .creative, isSelected: true, onTap: {})
            CategoryPill(category: .creative, isSelected: false, onTap: {})
        }
    }
    .padding()
}

