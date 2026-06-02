import SwiftUI

struct HistoryProjectRow: View {
    let summary: HistoryProjectSummary
    let onTap: () -> Void

    private let chevronGray = Color(red: 0xD0 / 255, green: 0xD0 / 255, blue: 0xD0 / 255)
    private let trackGray = Color(red: 0xF0 / 255, green: 0xF0 / 255, blue: 0xF0 / 255)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Circle()
                    .fill(summary.color)
                    .frame(width: 10, height: 10)

                Text(summary.displayName)
                    .font(.spaceGrotesk(.medium, size: 15))
                    .foregroundStyle(Color(red: 0x22 / 255, green: 0x22 / 255, blue: 0x22 / 255))
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text("\(summary.doneCount)/\(summary.totalCount)")
                    .font(.spaceGrotesk(.medium, size: 13))
                    .foregroundStyle(Color(red: 0xBB / 255, green: 0xBB / 255, blue: 0xBB / 255))

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(trackGray)
                        .frame(width: 40, height: 4)

                    Capsule()
                        .fill(summary.color)
                        .frame(width: 40 * CGFloat(summary.percent) / 100, height: 4)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(chevronGray)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
