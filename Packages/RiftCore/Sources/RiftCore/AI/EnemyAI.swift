public enum EnemyAIAction: Equatable, Sendable {
    case moveToward(targetID: String, distance: Double)
    case moveAway(targetID: String, distance: Double)
    case useSkill(skillID: String, targetID: String)
    case endTurn
}

public struct EnemyAIContext: Equatable, Sendable {
    public var skillsByID: [String: SkillDefinition]
    public var distancesByTargetID: [String: Double]
    public var lineOfSightByTargetID: [String: Bool]
    public var movementDistance: Double

    public init(
        skills: [SkillDefinition],
        distancesByTargetID: [String: Double],
        lineOfSightByTargetID: [String: Bool],
        movementDistance: Double = APRules.movementDistancePerAPStartingValue
    ) {
        var indexedSkills: [String: SkillDefinition] = [:]
        for skill in skills where indexedSkills[skill.id] == nil {
            indexedSkills[skill.id] = skill
        }
        self.skillsByID = indexedSkills
        self.distancesByTargetID = distancesByTargetID
        self.lineOfSightByTargetID = lineOfSightByTargetID
        self.movementDistance = movementDistance
    }

    public func skill(id: String) -> SkillDefinition? {
        skillsByID[id]
    }

    public func distance(to actorID: String) -> Double {
        distancesByTargetID[actorID] ?? .greatestFiniteMagnitude
    }

    public func hasLineOfSight(to actorID: String) -> Bool {
        lineOfSightByTargetID[actorID] == true
    }
}

public enum EnemyAI {
    public static func chooseAction(
        for actor: Actor,
        tendency explicitTendency: AITendency? = nil,
        in state: BattleState,
        context: EnemyAIContext
    ) -> EnemyAIAction {
        let skills = actor.skillIDs.compactMap { context.skill(id: $0) }
        let tendency = explicitTendency ?? AITendency.inferred(for: actor, skills: skills)

        switch tendency {
        case .melee:
            return chooseMeleeAction(for: actor, in: state, context: context)
        case .archer:
            return chooseArcherAction(for: actor, in: state, context: context)
        case .mage:
            return chooseMageAction(for: actor, in: state, context: context)
        case .rogue:
            return chooseRogueAction(for: actor, in: state, context: context)
        }
    }

    private static func chooseMeleeAction(
        for actor: Actor,
        in state: BattleState,
        context: EnemyAIContext
    ) -> EnemyAIAction {
        guard let target = closestOpponent(to: actor, in: state, context: context) else {
            return .endTurn
        }
        if let skill = usableSkills(for: actor, context: context).first(where: {
            canUse($0, on: target.id, context: context)
        }) {
            return .useSkill(skillID: skill.id, targetID: target.id)
        }
        return movementAction(.moveToward(targetID: target.id, distance: context.movementDistance), actor: actor)
    }

    private static func chooseArcherAction(
        for actor: Actor,
        in state: BattleState,
        context: EnemyAIContext
    ) -> EnemyAIAction {
        guard let target = closestOpponent(to: actor, in: state, context: context) else {
            return .endTurn
        }

        if context.distance(to: target.id) < 3.0 {
            return movementAction(.moveAway(targetID: target.id, distance: context.movementDistance), actor: actor)
        }

        let skills = usableSkills(for: actor, context: context).sorted { $0.range > $1.range }
        if let skill = skills.first(where: { canUse($0, on: target.id, context: context) }) {
            return .useSkill(skillID: skill.id, targetID: target.id)
        }
        return movementAction(.moveToward(targetID: target.id, distance: context.movementDistance), actor: actor)
    }

    private static func chooseMageAction(
        for actor: Actor,
        in state: BattleState,
        context: EnemyAIContext
    ) -> EnemyAIAction {
        let targets = livingOpponents(of: actor, in: state)
        let elementalSkills = usableSkills(for: actor, context: context)
            .filter(AITendency.isElemental)
            .sorted { $0.actionPointCost > $1.actionPointCost }

        for skill in elementalSkills {
            if let target = targets.first(where: { canUse(skill, on: $0.id, context: context) }) {
                return .useSkill(skillID: skill.id, targetID: target.id)
            }
        }
        return chooseArcherAction(for: actor, in: state, context: context)
    }

    private static func chooseRogueAction(
        for actor: Actor,
        in state: BattleState,
        context: EnemyAIContext
    ) -> EnemyAIAction {
        guard let target = livingOpponents(of: actor, in: state).min(by: { lhs, rhs in
            if lhs.stats.health == rhs.stats.health {
                return context.distance(to: lhs.id) < context.distance(to: rhs.id)
            }
            return lhs.stats.health < rhs.stats.health
        }) else {
            return .endTurn
        }

        let skills = usableSkills(for: actor, context: context).sorted { $0.actionPointCost > $1.actionPointCost }
        if let skill = skills.first(where: { canUse($0, on: target.id, context: context) }) {
            return .useSkill(skillID: skill.id, targetID: target.id)
        }
        return movementAction(.moveToward(targetID: target.id, distance: context.movementDistance), actor: actor)
    }

    private static func livingOpponents(of actor: Actor, in state: BattleState) -> [Actor] {
        state.actors.filter { candidate in
            candidate.stats.health > 0 && candidate.id != actor.id && isOpponent(candidate.faction, of: actor.faction)
        }
    }

    private static func closestOpponent(to actor: Actor, in state: BattleState, context: EnemyAIContext) -> Actor? {
        livingOpponents(of: actor, in: state).min { lhs, rhs in
            context.distance(to: lhs.id) < context.distance(to: rhs.id)
        }
    }

    private static func usableSkills(for actor: Actor, context: EnemyAIContext) -> [SkillDefinition] {
        actor.skillIDs
            .compactMap { context.skill(id: $0) }
            .filter { $0.target == .enemy && $0.actionPointCost <= actor.stats.actionPoints }
    }

    private static func canUse(
        _ skill: SkillDefinition,
        on targetID: String,
        context: EnemyAIContext
    ) -> Bool {
        context.distance(to: targetID) <= skill.range && context.hasLineOfSight(to: targetID)
    }

    private static func movementAction(_ action: EnemyAIAction, actor: Actor) -> EnemyAIAction {
        let distance: Double
        switch action {
        case let .moveToward(_, actionDistance), let .moveAway(_, actionDistance):
            distance = actionDistance
        default:
            return action
        }
        let cost = APRules.movementCost(forDistance: distance)
        return actor.stats.actionPoints >= cost ? action : .endTurn
    }

    private static func isOpponent(_ faction: Faction, of actorFaction: Faction) -> Bool {
        if actorFaction == .player {
            return faction == .hostile || faction == .animal || faction == .monster
        }
        return faction == .player
    }
}
