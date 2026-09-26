import SwiftUI

struct ProgressBar: View {
    let doneCount: Int
    let totalCount: Int

    private let pink = Color(red: 0xFF / 255, green: 0x33 / 255, blue: 0x99 / 255)
    private let fuchsia = Color(red: 0xE0 / 255, green: 0x40 / 255, blue: 0xFB / 255)

    @Environment(\.appTheme) private var theme

    private var clampedDone: Int {
        min(max(doneCount, 0), max(totalCount, 0))
    }

    private var clampedTotal: Int {
        max(totalCount, 0)
    }

    private var progress: CGFloat {
        guard clampedTotal > 0 else { return 0 }
        return CGFloat(clampedDone) / CGFloat(clampedTotal)
    }

    private var isComplete: Bool {
        clampedTotal > 0 && clampedDone == clampedTotal
    }

    private var percentageText: String {
        "\(Int((progress * 100).rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(clampedDone) of \(clampedTotal) done")
                    .font(.spaceGrotesk(.semibold, size: 12))
                    .foregroundStyle(theme.textMuted)

                Spacer()

                if isComplete {
                    Text("Complete")
                        .font(.spaceGrotesk(.bold, size: 12))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.violet)
                        .clipShape(Capsule())
                } else {
                    Text(percentageText)
                        .font(.spaceGrotesk(.bold, size: 12))
                        .foregroundStyle(AppTheme.violet)
                }
            }

            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(theme.progressBg)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: isComplete ? [AppTheme.violet, fuchsia] : [AppTheme.violet, pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width * progress, height: 10)
                        .animation(.easeOut(duration: 0.45), value: progress)
                }
            }
            .frame(height: 10)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBar(doneCount: 0, totalCount: 4)
        ProgressBar(doneCount: 2, totalCount: 4)
        ProgressBar(doneCount: 4, totalCount: 4)
    }
    .padding()
}

