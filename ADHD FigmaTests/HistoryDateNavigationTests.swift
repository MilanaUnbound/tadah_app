import Foundation
import Testing
@testable import ADHD_Figma

struct HistoryDateNavigationTests {
    @Test func landingKey_mostRecentInMonth() {
        let keys = ["2026-05-10", "2026-05-29", "2026-04-01"]
        let landing = HistoryDateNavigation.landingDateKey(
            year: 2026,
            month: 5,
            taskDateKeys: keys
        )
        #expect(landing == "2026-05-29")
    }

    @Test func landingKey_emptyMonth_fallsBackToFirst() {
        let keys = ["2026-04-15", "2026-06-01"]
        let landing = HistoryDateNavigation.landingDateKey(
            year: 2026,
            month: 5,
            taskDateKeys: keys
        )
        #expect(landing == "2026-05-01")
    }

    @Test func landingKey_singleDay() {
        let keys = ["2026-05-15"]
        let landing = HistoryDateNavigation.landingDateKey(
            year: 2026,
            month: 5,
            taskDateKeys: keys
        )
        #expect(landing == "2026-05-15")
    }
}
