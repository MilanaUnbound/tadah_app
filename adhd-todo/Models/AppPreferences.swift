import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light
    case dark
    case auto

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .auto: "Auto"
        }
    }

    var systemImageName: String {
        switch self {
        case .light: "sun.max"
        case .dark: "moon"
        case .auto: "display"
        }
    }
}

@Observable
final class AppPreferences {
    private enum Keys {
        static let appearanceMode = "appearanceMode"
        static let notificationsEnabled = "notificationsEnabled"
        static let reminderHour = "reminderHour"
        static let reminderMinute = "reminderMinute"
    }

    var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: Keys.appearanceMode) }
    }

    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    var reminderHour: Int {
        didSet { UserDefaults.standard.set(reminderHour, forKey: Keys.reminderHour) }
    }

    var reminderMinute: Int {
        didSet { UserDefaults.standard.set(reminderMinute, forKey: Keys.reminderMinute) }
    }

    init() {
        let defaults = UserDefaults.standard
        appearanceMode = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearanceMode) ?? "") ?? .auto
        notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        reminderHour = defaults.object(forKey: Keys.reminderHour) as? Int ?? 9
        reminderMinute = defaults.object(forKey: Keys.reminderMinute) as? Int ?? 0
    }

    var resolvedColorScheme: ColorScheme? {
        switch appearanceMode {
        case .light: .light
        case .dark: .dark
        case .auto: nil
        }
    }
}
