public struct TargetingContext: Equatable, Sendable {
    public var distance: Double
    public var hasLineOfSight: Bool
    public var isAlly: Bool

    public init(distance: Double, hasLineOfSight: Bool, isAlly: Bool) {
        self.distance = distance
        self.hasLineOfSight = hasLineOfSight
        self.isAlly = isAlly
    }
}

public enum TargetingError: Error, Equatable, Sendable {
    case outOfRange(maxRange: Double, actual: Double)
    case blockedLineOfSight
    case allyNotAllowed
}

public enum TargetingRules {
    public static func validate(skill: SkillDefinition, context: TargetingContext) throws {
        guard context.distance <= skill.range else {
            throw TargetingError.outOfRange(maxRange: skill.range, actual: context.distance)
        }
        guard context.hasLineOfSight else {
            throw TargetingError.blockedLineOfSight
        }
        if context.isAlly && !skill.affectsAllies {
            throw TargetingError.allyNotAllowed
        }
    }
}
