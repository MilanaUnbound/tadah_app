import Testing
@testable import ADHD_Figma

struct ADHD_FigmaTests {
    @Test func appModuleLoads() {
        #expect(RecurrenceGenerator.defaultHorizonDays == 60)
    }
}
