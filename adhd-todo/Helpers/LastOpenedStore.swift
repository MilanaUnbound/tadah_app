import Foundation

enum LastOpenedStore {
    private static let lastOpenedKey = "lastOpenedDateKey"

    static func getLastOpenedKey() -> String? {
        UserDefaults.standard.string(forKey: lastOpenedKey)
    }

    static func setLastOpenedKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: lastOpenedKey)
    }
}

