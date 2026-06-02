import SwiftUI
import Charts

struct CategoryDonutCard: View {
    let breakdowns: [RecapCalculator.CategoryBreakdown]
    let centerCount: Int
    var isCompact: Bool = false

    private let labelGray = Color(red: 0xAA / 255, green: 0xAA / 255, blue: 0xAA / 255)
    private let legendText = Color(red: 0x33 / 255, green: 0x33 / 255, blue: 0x33 / 255)

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : .white
    }

    private var chartHeight: CGFloat { isCompact ? 120 : 180 }
    private var headerBottomPadding: CGFloat { isCompact ? 12 : 20 }
    private var legendTopPadding: CGFloat { isCompact ? 12 : 20 }
    private var verticalPadding: CGFloat { isCompact ? 14 : 20 }
    private var horizontalPadding: CGFloat { isCompact ? 12 : 16 }
    private var centerCountSize: CGFloat { isCompact ? 22 : 26 }

    private var slices: [DonutSlice] {
        breakdowns
            .filter { $0.completedCount > 0 }
            .map { row in
                DonutSlice(
                    id: row.groupKey,
                    displayName: row.displayName,
                    count: row.completedCount,
                    color: Self.donutColor(hex: row.colorHex)
                )
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BY CATEGORY")
                .font(.spaceGrotesk(.medium, size: 12))
                .foregroundStyle(labelGray)
                .tracking(1)
                .textCase(.uppercase)
                .padding(.bottom, headerBottomPadding)

            ZStack {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Count", slice.count),
                        innerRadius: .ratio(0.71),
                        outerRadius: .ratio(1.0),
                        angularInset: slices.count > 1 ? 3 : 0
                    )
                    .foregroundStyle(slice.color)
                }
                .chartLegend(.hidden)
                .frame(height: chartHeight)

                VStack(spacing: 0) {
                    Text("\(centerCount)")
                        .font(.spaceGrotesk(.bold, size: centerCountSize))
                        .foregroundStyle(Color.primary)

                    Text("tasks")
                        .font(.spaceGrotesk(.medium, size: 11))
                        .foregroundStyle(labelGray)
                }
            }

            if slices.isEmpty == false {
                legend
                    .padding(.top, legendTopPadding)
            }
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var legend: some View {
        if isCompact {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6),
                ],
                spacing: 6
            ) {
                ForEach(slices) { slice in
                    legendRow(slice: slice, fontSize: 12)
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(slices) { slice in
                    legendRow(slice: slice, fontSize: 14)
                }
            }
        }
    }

    private func legendRow(slice: DonutSlice, fontSize: CGFloat) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(slice.color)
                .frame(width: 10, height: 10)

            Text(slice.displayName)
                .font(.spaceGrotesk(.medium, size: fontSize))
                .foregroundStyle(colorScheme == .dark ? Color.primary : legendText)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("\(slice.count)")
                .font(.spaceGrotesk(.semibold, size: fontSize))
                .foregroundStyle(Color.primary)
        }
    }

    static func donutColor(hex: String) -> Color {
        Color(hex: hex) ?? donutColor(for: .other)
    }

    static func donutColor(for category: Category) -> Color {
        switch category {
        case .work:
            Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)
        case .health:
            Color(red: 0x22 / 255, green: 0xC5 / 255, blue: 0x5E / 255)
        case .home:
            Color(red: 0xF9 / 255, green: 0x73 / 255, blue: 0x16 / 255)
        case .groceries:
            Color(red: 0xF5 / 255, green: 0x9E / 255, blue: 0x0B / 255)
        case .social:
            Color(red: 0xEC / 255, green: 0x48 / 255, blue: 0x99 / 255)
        case .creative:
            Color(red: 0xC0 / 255, green: 0x84 / 255, blue: 0xFC / 255)
        case .other:
            Color(red: 0x6B / 255, green: 0x72 / 255, blue: 0x80 / 255)
        }
    }
}

private struct DonutSlice: Identifiable {
    let id: String
    let displayName: String
    let count: Int
    let color: Color
}

#Preview {
    CategoryDonutCard(
        breakdowns: [
            .init(
                groupKey: "work",
                displayName: "Work",
                colorHex: "#7B2FFF",
                completedCount: 5,
                completedPercent: 50
            ),
            .init(
                groupKey: "health",
                displayName: "Health",
                colorHex: "#22C55E",
                completedCount: 3,
                completedPercent: 30
            ),
        ],
        centerCount: 8,
        isCompact: true
    )
    .padding()
    .background(Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255))
}
