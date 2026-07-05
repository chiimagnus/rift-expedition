public enum BattleActionError: Error, Equatable, Sendable {
    case battleAlreadyEnded(BattleOutcome)
    case noActiveActor
    case actorNotFound(String)
    case notActorsTurn(expected: String, actual: String)
    case insufficientActionPoints(required: Int, available: Int)
}

public struct BattleEngine: Sendable {
    public private(set) var state: BattleState

    public init(state: BattleState) {
        self.state = state
    }

    public mutating func move(actorID: String, distance: Double) throws {
        try spendActionPoints(actorID: actorID, cost: APRules.movementCost(forDistance: distance))
    }

    public mutating func useSkill(actorID: String, skill: SkillDefinition) throws {
        try spendActionPoints(actorID: actorID, cost: skill.actionPointCost)
    }

    public mutating func useSkill<R: RandomSource>(
        actorID: String,
        targetID: String,
        skill: SkillDefinition,
        context: TargetingContext,
        random: inout R
    ) throws -> SkillResolution {
        try ensureBattleIsOngoing()
        guard state.actor(id: actorID) != nil else {
            throw BattleActionError.actorNotFound(actorID)
        }
        guard state.actor(id: targetID) != nil else {
            throw BattleActionError.actorNotFound(targetID)
        }
        try TargetingRules.validate(skill: skill, context: context)
        try spendActionPoints(actorID: actorID, cost: skill.actionPointCost)
        return try SkillResolver.resolve(
            skill: skill,
            casterID: actorID,
            targetID: targetID,
            context: context,
            in: &state,
            random: &random
        )
    }

    public mutating func endTurn() throws {
        try ensureBattleIsOngoing()
        guard state.activeActorID != nil else {
            throw BattleActionError.noActiveActor
        }

        state.turnOrder.advance()
        if state.turnOrder.activeIndex == 0 {
            state.round += 1
        }
        if let nextActorID = state.activeActorID {
            _ = state.updateActor(id: nextActorID) { actor in
                actor.stats.actionPoints = actor.stats.maxActionPoints
            }
        }
    }

    private mutating func spendActionPoints(actorID: String, cost: Int) throws {
        try ensureBattleIsOngoing()
        guard let activeActorID = state.activeActorID else {
            throw BattleActionError.noActiveActor
        }
        guard activeActorID == actorID else {
            throw BattleActionError.notActorsTurn(expected: activeActorID, actual: actorID)
        }
        guard let actor = state.actor(id: actorID) else {
            throw BattleActionError.actorNotFound(actorID)
        }
        guard actor.stats.actionPoints >= cost else {
            throw BattleActionError.insufficientActionPoints(required: cost, available: actor.stats.actionPoints)
        }

        _ = state.updateActor(id: actorID) { actor in
            actor.stats.actionPoints -= cost
        }
    }

    private func ensureBattleIsOngoing() throws {
        let outcome = state.outcome
        if outcome != .ongoing {
            throw BattleActionError.battleAlreadyEnded(outcome)
        }
    }
}
