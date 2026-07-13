public enum PartyInventoryValidationError: Error, Equatable, Sendable {
    case emptyItemID
    case nonPositiveQuantity(itemID: String, quantity: Int)
}

public struct PartyInventory: Codable, Equatable, Sendable {
    public private(set) var itemCounts: [String: Int]

    public init() {
        itemCounts = [:]
    }

    public init(itemCounts: [String: Int]) throws {
        self.itemCounts = itemCounts
        try validate()
    }

    private enum CodingKeys: String, CodingKey {
        case itemCounts
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        itemCounts = try container.decode([String: Int].self, forKey: .itemCounts)
        try validate()
    }

    public func encode(to encoder: any Encoder) throws {
        try validate()
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(itemCounts, forKey: .itemCounts)
    }

    public func validate() throws {
        for (itemID, quantity) in itemCounts {
            guard !itemID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PartyInventoryValidationError.emptyItemID
            }
            guard quantity > 0 else {
                throw PartyInventoryValidationError.nonPositiveQuantity(itemID: itemID, quantity: quantity)
            }
        }
    }

    public func count(of itemID: String) -> Int {
        itemCounts[itemID, default: 0]
    }

    public mutating func addItem(id: String, quantity: Int = 1) {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, quantity > 0 else { return }
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
