import SwiftUI

enum Category: String, CaseIterable, Identifiable, Codable {
    case work
    case health
    case home
    case groceries
    case social
    case creative
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .work: "Work"
        case .health: "Health"
        case .home: "Home"
        case .groceries: "Groceries"
        case .social: "Social"
        case .creative: "Creative"
        case .other: "Other"
        }
    }

    var color: Color {
        switch self {
        case .work: Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)
        case .health: Color(red: 0x00 / 255, green: 0xC8 / 255, blue: 0x75 / 255)
        case .home: Color(red: 0xFF / 255, green: 0x6B / 255, blue: 0x00 / 255)
        case .groceries: Color(red: 0xE8 / 255, green: 0xA8 / 255, blue: 0x00 / 255)
        case .social: Color(red: 0xFF / 255, green: 0x33 / 255, blue: 0x99 / 255)
        case .creative: Color(red: 0xE0 / 255, green: 0x40 / 255, blue: 0xFB / 255)
        case .other: Color(red: 0x6B / 255, green: 0x72 / 255, blue: 0x80 / 255)
        }
    }

    var lightColor: Color {
        switch self {
        case .work: Color(red: 0xED / 255, green: 0xE8 / 255, blue: 0xFF / 255)
        case .health: Color(red: 0xE0 / 255, green: 0xFF / 255, blue: 0xF3 / 255)
        case .home: Color(red: 0xFF / 255, green: 0xE8 / 255, blue: 0xD6 / 255)
        case .groceries: Color(red: 0xFF / 255, green: 0xF5 / 255, blue: 0xCC / 255)
        case .social: Color(red: 0xFF / 255, green: 0xE0 / 255, blue: 0xEF / 255)
        case .creative: Color(red: 0xF8 / 255, green: 0xE0 / 255, blue: 0xFF / 255)
        case .other: Color(red: 0xF3 / 255, green: 0xF4 / 255, blue: 0xF6 / 255)
        }
    }
}

