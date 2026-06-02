import SwiftUI

struct ProgressBar: View {
    let doneCount: Int
    let totalCount: Int

    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)
    private let pink = Color(red: 0xFF / 255, green: 0x33 / 255, blue: 0x99 / 255)
    private let fuchsia = Color(red: 0xE0 / 255, green: 0x40 / 255, blue: 0xFB / 255)
    private let textMuted = Color(red: 0x6B / 255, green: 0x72 / 255, blue: 0x80 / 255)

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
                    .foregroundStyle(textMuted)

                Spacer()

                if isComplete {
                    Text("Complete")
                        .font(.spaceGrotesk(.bold, size: 12))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(violet)
                        .clipShape(Capsule())
                } else {
                    Text(percentageText)
                        .font(.spaceGrotesk(.bold, size: 12))
                        .foregroundStyle(violet)
                }
            }

            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color(red: 0xE5 / 255, green: 0xE7 / 255, blue: 0xEB / 255))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: isComplete ? [violet, fuchsia] : [violet, pink],
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

