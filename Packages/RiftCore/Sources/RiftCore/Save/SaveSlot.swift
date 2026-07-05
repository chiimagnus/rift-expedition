public enum SaveSlotKind: String, Codable, Sendable {
    case manual
    case auto
}

public struct SaveSlot: Codable, Equatable, Hashable, Sendable {
    public var kind: SaveSlotKind
    public var index: Int

    public init(kind: SaveSlotKind, index: Int) {
        self.kind = kind
        self.index = index
    }

    public static func manual(_ index: Int) -> SaveSlot {
        SaveSlot(kind: .manual, index: index)
    }

    public static func auto(_ index: Int) -> SaveSlot {
        SaveSlot(kind: .auto, index: index)
    }
}
