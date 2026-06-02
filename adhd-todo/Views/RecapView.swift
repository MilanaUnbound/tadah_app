import SwiftUI
import SwiftData

struct RecapView: View {
    @Environment(\.screenContentWidth) private var screenContentWidth

    let streakCount: Int

    @Query private var allTasks: [Task]
    @Query(sort: \Project.name) private var projects: [Project]
    @State private var periodMode: RecapPeriodMode = .month
    @State private var viewYear: Int
    @State private var viewMonth: Int
    @State private var streakWidth: CGFloat = StreakBadgeLayout.defaultWidth

    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)

    private let catHealth = Color(red: 0x00 / 255, green: 0xC8 / 255, blue: 0x75 / 255)
    private let bgDone = Color(red: 0xE0 / 255, green: 0xFF / 255, blue: 0xF3 / 255)
    private let bgRate = Color(red: 0xED / 255, green: 0xE8 / 255, blue: 0xFF / 255)
    private let cardSurface = Color(.secondarySystemBackground)

    private static let compactHeightThreshold: CGFloat = 640

    init(streakCount: Int) {
        self.streakCount = streakCount
        let calendar = Calendar.current
        let now = Date()
        _viewYear = State(initialValue: calendar.component(.year, from: now))
        _viewMonth = State(initialValue: calendar.component(.month, from: now))
        _allTasks = Query(sort: [
            SortDescriptor(\Task.dateKey, order: .reverse),
            SortDescriptor(\Task.title),
        ])
    }

    private var periodLabel: String {
        switch periodMode {
        case .year:
            return String(viewYear)
        case .month:
            return DateHelpers.navigatorMonthAbbreviation(year: viewYear, month: viewMonth)
        }
    }

    private var recapSummary: RecapCalculator.Summary {
        let period: RecapCalculator.Period = {
            switch periodMode {
            case .month: .month(year: viewYear, month: viewMonth)
            case .year: .year(viewYear)
            }
        }()

        return RecapCalculator.calculate(
            allTasks: allTasks,
            period: period,
            projects: projects
        )
    }

    private var hasAnyData: Bool {
        recapSummary.totalAdded > 0
    }

    private var topCategoryInsight: (name: String, percent: Int, colorHex: String)? {
        guard recapSummary.totalCompleted > 0 else { return nil }
        guard let top = recapSummary.byCategory.first(where: { $0.completedCount > 0 }) else { return nil }
        let percent = Int(
            round(
                (Double(top.completedCount) / Double(recapSummary.totalCompleted)) * 100
            )
        )
        return (top.displayName, percent, top.colorHex)
    }

    var body: some View {
        GeometryReader { geo in
            let isCompactHeight = geo.size.height < Self.compactHeightThreshold
            let titleSize = min(
                isCompactHeight ? 26 : 30,
                ScreenLayout.headingFontSize(for: screenContentWidth)
            )

            VStack(alignment: .leading, spacing: isCompactHeight ? 10 : 16) {
                HStack(alignment: .center) {
                    Text("Recap")
                        .font(.spaceGrotesk(.bold, size: titleSize))

                    Spacer()

                    StreakBadge(streakCount: streakCount)
                        .streakWidthReporter()
                }

                RecapPeriodControl(
                    periodMode: $periodMode,
                    periodLabel: periodLabel,
                    navigatorWidth: streakWidth,
                    onPrevious: { stepPeriod(direction: -1) },
                    onNext: { stepPeriod(direction: 1) }
                )

                if hasAnyData == false {
                    Text("No data yet. Start adding tasks to see your recap.")
                        .font(.spaceGrotesk(.medium, size: 14))
                        .foregroundStyle(Color.secondary)
                        .padding(.top, 8)

                    Spacer(minLength: 0)
                } else {
                    summaryCards(isCompactHeight: isCompactHeight)

                    CategoryDonutCard(
                        breakdowns: recapSummary.byCategory,
                        centerCount: recapSummary.totalCompleted,
                        isCompact: isCompactHeight
                    )

                    if let top = topCategoryInsight {
                        RecapInsightCard(
                            categoryName: top.name,
                            percent: top.percent,
                            accentColor: CategoryDonutCard.donutColor(hex: top.colorHex),
                            isCompact: isCompactHeight
                        )
                    }

                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .tabContentVerticalPadding()
            .onStreakWidth { streakWidth = $0 }
        }
    }

    private func stepPeriod(direction: Int) {
        withAnimation(.easeOut(duration: 0.15)) {
            switch periodMode {
            case .month:
                HistoryBrowseHelper.stepMonth(
                    viewYear: &viewYear,
                    viewMonth: &viewMonth,
                    direction: direction
                )
            case .year:
                HistoryBrowseHelper.stepYear(viewYear: &viewYear, direction: direction)
            }
        }
    }

    private func summaryCards(isCompactHeight: Bool) -> some View {
        HStack(spacing: isCompactHeight ? 8 : 12) {
            SummaryCard(
                title: "Tasks",
                value: "\(recapSummary.totalAdded)",
                background: cardSurface,
                valueColor: Color.primary,
                isCompactHeight: isCompactHeight,
                screenWidth: screenContentWidth
            )

            SummaryCard(
                title: "Done",
                value: "\(recapSummary.totalCompleted)",
                background: bgDone,
                valueColor: catHealth,
                isCompactHeight: isCompactHeight,
                screenWidth: screenContentWidth
            )

            SummaryCard(
                title: "Rate",
                value: "\(recapSummary.completionRate)%",
                background: bgRate,
                valueColor: violet,
                isCompactHeight: isCompactHeight,
                screenWidth: screenContentWidth
            )
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let background: Color
    let valueColor: Color
    var isCompactHeight: Bool = false
    var screenWidth: CGFloat = ScreenLayout.defaultContentWidth

    private var valueFontSize: CGFloat {
        let heightBased: CGFloat = isCompactHeight ? 20 : 24
        return min(heightBased, ScreenLayout.summaryValueFontSize(for: screenWidth))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompactHeight ? 4 : 6) {
            Text(title)
                .font(.spaceGrotesk(.semibold, size: 12))
                .foregroundStyle(Color.secondary)

            Text(value)
                .font(.spaceGrotesk(.bold, size: valueFontSize))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(isCompactHeight ? 10 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

#Preview {
    RecapView(streakCount: 14)
}
