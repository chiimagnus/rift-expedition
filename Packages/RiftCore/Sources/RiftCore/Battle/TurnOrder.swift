public struct TurnOrder: Codable, Equatable, Sendable {
    public private(set) var actorIDs: [String]
    public private(set) var activeIndex: Int

    public init(actorIDs: [String], activeIndex: Int = 0) {
        self.actorIDs = actorIDs
        self.activeIndex = actorIDs.isEmpty ? 0 : min(max(activeIndex, 0), actorIDs.count - 1)
    }

    public var activeActorID: String? {
        guard !actorIDs.isEmpty else { return nil }
        return actorIDs[activeIndex]
    }

    public mutating func advance() {
        guard !actorIDs.isEmpty else { return }
        activeIndex = (activeIndex + 1) % actorIDs.count
    }
}
