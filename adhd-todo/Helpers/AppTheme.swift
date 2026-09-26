import SwiftUI

struct AppTheme {
    let bg: Color
    let card: Color
    let sheet: Color
    let text: Color
    let textSub: Color
    let textMuted: Color
    let textFaint: Color
    let border: Color
    let tabBg: Color
    let btnBg: Color
    let inputBg: Color
    let progressBg: Color
    let checkBorder: Color
    let insightBg: Color
    let insightText: Color
    let cardShadowOpacity: Double

    static let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)
    static let exportBlue = Color(red: 0x3B / 255, green: 0x82 / 255, blue: 0xF6 / 255)
    static let importGreen = Color(red: 0x22 / 255, green: 0xC5 / 255, blue: 0x5E / 255)
    static let reminderPink = Color(red: 0xEC / 255, green: 0x48 / 255, blue: 0x99 / 255)
    static let deleteRed = Color(red: 0xEF / 255, green: 0x44 / 255, blue: 0x44 / 255)
    static let toggleOff = Color(red: 0xE0 / 255, green: 0xE0 / 255, blue: 0xE0 / 255)
    static let milestoneYellow = Color(red: 0xFF / 255, green: 0xCC / 255, blue: 0x00 / 255)

    static let light = AppTheme(
        bg: Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255),
        card: .white,
        sheet: .white,
        text: Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255),
        textSub: Color(red: 0x77 / 255, green: 0x77 / 255, blue: 0x77 / 255),
        textMuted: Color(red: 0xAA / 255, green: 0xAA / 255, blue: 0xAA / 255),
        textFaint: Color(red: 0xCC / 255, green: 0xCC / 255, blue: 0xCC / 255),
        border: Color(red: 0xEF / 255, green: 0xEF / 255, blue: 0xEF / 255),
        tabBg: Color(red: 0xE8 / 255, green: 0xE8 / 255, blue: 0xEA / 255),
        btnBg: Color(red: 0xF0 / 255, green: 0xF0 / 255, blue: 0xF2 / 255),
        inputBg: Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255),
        progressBg: Color(red: 0xE0 / 255, green: 0xE0 / 255, blue: 0xE0 / 255),
        checkBorder: Color(red: 0xD0 / 255, green: 0xD0 / 255, blue: 0xD0 / 255),
        insightBg: Color(red: 0xF5 / 255, green: 0xF1 / 255, blue: 0xFF / 255),
        insightText: Color(red: 0x22 / 255, green: 0x22 / 255, blue: 0x22 / 255),
        cardShadowOpacity: 0.05
    )

    static let dark = AppTheme(
        bg: .black,
        card: Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255),
        sheet: Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255),
        text: Color(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF7 / 255),
        textSub: Color(red: 0x8E / 255, green: 0x8E / 255, blue: 0x93 / 255),
        textMuted: Color(red: 0x63 / 255, green: 0x63 / 255, blue: 0x66 / 255),
        textFaint: Color(red: 0x48 / 255, green: 0x48 / 255, blue: 0x4A / 255),
        border: Color(red: 0x38 / 255, green: 0x38 / 255, blue: 0x3A / 255),
        tabBg: Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255),
        btnBg: Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255),
        inputBg: Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255),
        progressBg: Color(red: 0x3A / 255, green: 0x3A / 255, blue: 0x3C / 255),
        checkBorder: Color(red: 0x48 / 255, green: 0x48 / 255, blue: 0x4A / 255),
        insightBg: Color(red: 0x1E / 255, green: 0x13 / 255, blue: 0x33 / 255),
        insightText: Color(red: 0xE8 / 255, green: 0xE0 / 255, blue: 0xFF / 255),
        cardShadowOpacity: 0.35
    )

    static func current(for colorScheme: ColorScheme) -> AppTheme {
        colorScheme == .dark ? .dark : .light
    }

    var cardShadowColor: Color {
        Color.black.opacity(cardShadowOpacity)
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.light
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

private struct AppThemeProvider: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.environment(\.appTheme, AppTheme.current(for: colorScheme))
    }
}

extension View {
    func withAppTheme() -> some View {
        modifier(AppThemeProvider())
    }
}
