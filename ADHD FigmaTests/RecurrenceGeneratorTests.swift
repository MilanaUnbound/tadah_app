import Foundation
import Testing
@testable import ADHD_Figma

struct RecurrenceGeneratorTests {
  private var calendar: Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Europe/London")!
    return cal
  }

  private var anchor: Date {
    var comps = DateComponents()
    comps.year = 2026
    comps.month = 5
    comps.day = 29
    return calendar.date(from: comps)!
  }

  @Test func daily_generatesSixtyInstances() {
    let result = RecurrenceGenerator.generate(
      title: "Water plants",
      category: .home,
      anchorDate: anchor,
      rule: .daily,
      customWeekdays: [],
      seriesId: UUID(),
      horizonDays: 60,
      calendar: calendar
    )

    guard case .success(let tasks) = result else {
      Issue.record("Expected success")
      return
    }

    #expect(tasks.count == 60)
    #expect(Set(tasks.map(\.recurrenceSeriesId)).count == 1)
    #expect(tasks.allSatisfy { $0.recurrenceRule == .daily })
  }

  @Test func weekly_generatesNineInstancesInSixtyDayWindow() {
    let result = RecurrenceGenerator.generate(
      title: "Review",
      category: .work,
      anchorDate: anchor,
      rule: .weekly,
      customWeekdays: [],
      seriesId: UUID(),
      horizonDays: 60,
      calendar: calendar
    )

    guard case .success(let tasks) = result else {
      Issue.record("Expected success")
      return
    }

    // Anchor + 8 more weeks = 9 occurrences within 60 days.
    #expect(tasks.count == 9)
  }

  @Test func custom_requiresWeekdays() {
    let result = RecurrenceGenerator.generate(
      title: "Gym",
      category: .health,
      anchorDate: anchor,
      rule: .custom,
      customWeekdays: [],
      calendar: calendar
    )

    guard case .failure(let error) = result else {
      Issue.record("Expected failure")
      return
    }

    #expect(error == .emptySchedule)
  }

  @Test func custom_monWedFri_fromFridayAnchor() {
    // 2026-05-29 is a Friday — anchor day matches Fri in Mon/Wed/Fri set.
    let weekdaySet: Set<Int> = [2, 4, 6] // Mon, Wed, Fri

    let result = RecurrenceGenerator.generate(
      title: "Gym",
      category: .health,
      anchorDate: anchor,
      rule: .custom,
      customWeekdays: weekdaySet,
      seriesId: UUID(),
      horizonDays: 60,
      calendar: calendar
    )

    guard case .success(let tasks) = result else {
      Issue.record("Expected success")
      return
    }

    #expect(tasks.isEmpty == false)
    let firstKey = tasks.first?.dateKey
    #expect(firstKey == "2026-05-29")
  }

  @Test func daily_uniqueDateKeysSpanWindow() {
    let seriesId = UUID()
    let result = RecurrenceGenerator.generate(
      title: "Water plants",
      category: .home,
      anchorDate: anchor,
      rule: .daily,
      customWeekdays: [],
      seriesId: seriesId,
      horizonDays: 60,
      calendar: calendar
    )

    guard case .success(let tasks) = result else {
      Issue.record("Expected success")
      return
    }

    let keys = tasks.map(\.dateKey)
    #expect(Set(keys).count == 60)
    #expect(keys.first == "2026-05-29")
    #expect(keys.last == "2026-07-27")
  }

  @Test func instances_shareSeriesIdAndShowRepeat() {
    let seriesId = UUID()
    let result = RecurrenceGenerator.generate(
      title: "Meditate",
      category: .health,
      anchorDate: anchor,
      rule: .daily,
      customWeekdays: [],
      seriesId: seriesId,
      horizonDays: 60,
      calendar: calendar
    )

    guard case .success(let tasks) = result else {
      Issue.record("Expected success")
      return
    }

    #expect(tasks.allSatisfy { $0.recurrenceSeriesId == seriesId })
    #expect(tasks.allSatisfy { $0.showsRepeatIcon })
  }
}
