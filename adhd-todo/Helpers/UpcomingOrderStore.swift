import Foundation

enum UpcomingOrderStore {
    private static let storageKey = "upcomingItemOrder"

    static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }

    static func save(_ order: [String]) {
        UserDefaults.standard.set(order, forKey: storageKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    /// Keeps saved order for existing items; appends newly appeared items at the end (date-sorted among themselves).
    static func merge(
        itemIDs: [String],
        defaultOrderForNew: (_ lhs: String, _ rhs: String) -> Bool,
        savedOrder: [String]
    ) -> [String] {
        let idSet = Set(itemIDs)
        var order = savedOrder.filter { idSet.contains($0) }

        let newIDs = itemIDs.filter { order.contains($0) == false }
            .sorted(by: defaultOrderForNew)
        order.append(contentsOf: newIDs)

        return order
    }

    static func move(itemID: String, toIndex: Int, in order: inout [String]) {
        guard let sourceIndex = order.firstIndex(of: itemID) else { return }

        var reordered = order
        reordered.remove(at: sourceIndex)
        let clampedIndex = min(max(0, toIndex), reordered.count)
        reordered.insert(itemID, at: clampedIndex)
        order = reordered
    }
}
