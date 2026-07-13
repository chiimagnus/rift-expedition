public enum BattleActionError: Error, Equatable, Sendable {
    case battleAlreadyEnded(BattleOutcome)
    case noActiveActor
    case actorNotFound(String)
    case notActorsTurn(expected: String, actual: String)
    case skillNotKnown(actorID: String, skillID: String)
    case invalidActionPointCost(Int)
    case invalidMovementDistance
    case insufficientActionPoints(required: Int, available: Int)
}

public struct BattleEngine: Sendable {
    public private(set) var state: BattleState

    public init(state: BattleState) {
        self.state = state
    }

    public mutating func move(actorID: String, distance: Double) throws {
        guard distance.isFinite, distance > 0 else {
            throw BattleActionError.invalidMovementDistance
        }
        try spendActionPoints(actorID: actorID, cost: APRules.movementCost(forDistance: distance))
    }

    public mutating func useSkill<R: RandomSource>(
        actorID: String,
        targetID: String,
        skill: SkillDefinition,
        context: TargetingContext,
        random: inout R
    ) throws -> SkillResolution {
        try ensureBattleIsOngoing()
        guard let caster = state.actor(id: actorID) else {
            throw BattleActionError.actorNotFound(actorID)
        }
        guard let target = state.actor(id: targetID) else {
            throw BattleActionError.actorNotFound(targetID)
        }
        guard caster.skillIDs.contains(skill.id) else {
            throw BattleActionError.skillNotKnown(actorID: actorID, skillID: skill.id)
        }
        try TargetingRules.validate(skill: skill, caster: caster, target: target, context: context)
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
        guard let endingActorID = state.activeActorID else {
            throw BattleActionError.noActiveActor
        }

        _ = state.updateActor(id: endingActorID) { actor in
            ElementResolver.tickStatuses(on: &actor)
        }
        guard state.outcome == .ongoing else { return }

        let actorCount = state.turnOrder.actorIDs.count
        guard actorCount > 0 else { throw BattleActionError.noActiveActor }

        for _ in 0..<actorCount {
            let previousIndex = state.turnOrder.activeIndex
            state.turnOrder.advance()
            if state.turnOrder.activeIndex <= previousIndex {
                state.round += 1
            }

            guard let nextActorID = state.activeActorID,
                  let nextActor = state.actor(id: nextActorID)
            else {
                continue
            }
            guard nextActor.stats.health > 0 else { continue }

            _ = state.updateActor(id: nextActorID) { actor in
                actor.stats.actionPoints = actor.stats.maxActionPoints
            }
            return
        }

        throw BattleActionError.noActiveActor
    }

    private mutating func spendActionPoints(actorID: String, cost: Int) throws {
        try ensureBattleIsOngoing()
        guard cost >= 0 else {
            throw BattleActionError.invalidActionPointCost(cost)
        }
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
