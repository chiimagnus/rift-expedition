public struct TargetingContext: Equatable, Sendable {
    public var distance: Double
    public var hasLineOfSight: Bool

    public init(distance: Double, hasLineOfSight: Bool) {
        self.distance = distance
        self.hasLineOfSight = hasLineOfSight
    }
}

public enum TargetRelation: String, Equatable, Sendable {
    case selfTarget
    case ally
    case enemy
    case neutral
}

public enum TargetingError: Error, Equatable, Sendable {
    case outOfRange(maxRange: Double, actual: Double)
    case blockedLineOfSight
    case invalidSkillTargetConfiguration(skillID: String)
    case invalidTarget(expected: SkillTarget, actual: TargetRelation)
}

public enum TargetingRules {
    public static func validate(
        skill: SkillDefinition,
        caster: Actor,
        target: Actor,
        context: TargetingContext
    ) throws {
        guard context.distance.isFinite, context.distance >= 0, context.distance <= skill.range else {
            throw TargetingError.outOfRange(maxRange: skill.range, actual: context.distance)
        }
        guard context.hasLineOfSight else {
            throw TargetingError.blockedLineOfSight
        }
        guard isTargetConfigurationValid(skill) else {
            throw TargetingError.invalidSkillTargetConfiguration(skillID: skill.id)
        }

        let relation = relation(from: caster, to: target)
        let isAllowed: Bool
        switch skill.target {
        case .selfOnly:
            isAllowed = relation == .selfTarget
        case .ally:
            isAllowed = relation == .selfTarget || relation == .ally
        case .enemy:
            isAllowed = relation == .enemy
        }
        guard isAllowed else {
            throw TargetingError.invalidTarget(expected: skill.target, actual: relation)
        }
    }

    private static func isTargetConfigurationValid(_ skill: SkillDefinition) -> Bool {
        switch skill.target {
        case .selfOnly, .ally:
            return skill.affectsAllies
        case .enemy:
            return !skill.affectsAllies
        }
    }

    private static func relation(from caster: Actor, to target: Actor) -> TargetRelation {
        if caster.id == target.id {
            return .selfTarget
        }
        if caster.faction == target.faction {
            return .ally
        }
        if isOpponent(target.faction, of: caster.faction) {
            return .enemy
        }
        return .neutral
    }

    private static func isOpponent(_ targetFaction: Faction, of casterFaction: Faction) -> Bool {
        if casterFaction == .player {
            return targetFaction == .hostile || targetFaction == .animal || targetFaction == .monster
        }
        return targetFaction == .player
    }
}
