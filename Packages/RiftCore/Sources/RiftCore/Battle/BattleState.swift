public enum BattleOutcome: String, Codable, Equatable, Sendable {
    case ongoing
    case victory
    case defeat
}

public struct BattleState: Codable, Equatable, Sendable {
    public var actors: [Actor]
    public var turnOrder: TurnOrder
    public var round: Int

    public init(actors: [Actor], round: Int = 1) {
        self.actors = actors
        self.turnOrder = TurnOrder(actorIDs: actors.map(\.id))
        self.round = round
    }

    public var activeActorID: String? {
        turnOrder.activeActorID
    }

    public var outcome: BattleOutcome {
        if allActorsDown(where: { $0.faction == .player }) {
            return .defeat
        }
        if allActorsDown(where: { $0.faction == .hostile || $0.faction == .animal || $0.faction == .monster }) {
            return .victory
        }
        return .ongoing
    }

    public func actor(id: String) -> Actor? {
        actors.first { $0.id == id }
    }

    public mutating func updateActor(id: String, _ update: (inout Actor) -> Void) -> Bool {
        guard let index = actors.firstIndex(where: { $0.id == id }) else { return false }
        update(&actors[index])
        return true
    }

    private func allActorsDown(where isIncluded: (Actor) -> Bool) -> Bool {
        let includedActors = actors.filter(isIncluded)
        return !includedActors.isEmpty && includedActors.allSatisfy { $0.stats.health <= 0 }
    }
}
