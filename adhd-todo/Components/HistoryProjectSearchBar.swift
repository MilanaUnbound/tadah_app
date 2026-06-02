import SwiftUI

struct HistoryProjectSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(red: 0xBB / 255, green: 0xBB / 255, blue: 0xBB / 255))

            TextField("Search projects…", text: $text)
                .font(.spaceGrotesk(.medium, size: 14))
                .foregroundStyle(Color(red: 0x33 / 255, green: 0x33 / 255, blue: 0x33 / 255))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}
