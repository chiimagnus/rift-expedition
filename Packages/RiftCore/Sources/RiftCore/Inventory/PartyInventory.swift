public struct PartyInventory: Codable, Equatable, Sendable {
    public private(set) var itemCounts: [String: Int]

    public init(itemCounts: [String: Int] = [:]) {
        self.itemCounts = itemCounts.filter { $0.value > 0 }
    }

    public func count(of itemID: String) -> Int {
        itemCounts[itemID, default: 0]
    }

    public mutating func addItem(id: String, quantity: Int = 1) {
        guard quantity > 0 else { return }
        itemCounts[id, default: 0] += quantity
    }

    public mutating func removeItem(id: String, quantity: Int = 1) throws {
        guard quantity > 0 else { return }
        let current = count(of: id)
        guard current >= quantity else {
            throw InventoryError.insufficientQuantity(itemID: id, required: quantity, available: current)
        }
        let remaining = current - quantity
        if remaining == 0 {
            itemCounts[id] = nil
        } else {
            itemCounts[id] = remaining
        }
    }
}

public enum InventoryError: Error, Equatable, Sendable {
    case insufficientQuantity(itemID: String, required: Int, available: Int)
}
