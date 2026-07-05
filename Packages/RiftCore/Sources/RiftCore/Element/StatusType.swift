public enum StatusType: String, Codable, CaseIterable, Sendable {
    case burning
    case wet
    case poisoned
}

public struct StatusEffect: Codable, Equatable, Sendable {
    public var type: StatusType
    public var remainingTurns: Int

    public init(type: StatusType, remainingTurns: Int) {
        self.type = type
        self.remainingTurns = remainingTurns
    }
}
