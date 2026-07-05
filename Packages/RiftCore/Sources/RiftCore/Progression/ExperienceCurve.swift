public struct LevelUpResult: Equatable, Sendable {
    public var levelsGained: Int
    public var attributePointsGained: Int

    public init(levelsGained: Int, attributePointsGained: Int) {
        self.levelsGained = levelsGained
        self.attributePointsGained = attributePointsGained
    }
}

public enum ExperienceCurve {
    public static let attributePointsPerLevel = 2

    public static func experienceRequired(forLevel level: Int) -> Int {
        max(0, (level - 1) * 100)
    }

    public static func grantExperience(_ amount: Int, to actor: inout Actor) -> LevelUpResult {
        actor.experience += max(0, amount)
        var levelsGained = 0

        while actor.experience >= experienceRequired(forLevel: actor.level + 1) {
            actor.level += 1
            levelsGained += 1
        }

        let points = levelsGained * attributePointsPerLevel
        actor.unspentAttributePoints += points
        return LevelUpResult(levelsGained: levelsGained, attributePointsGained: points)
    }
}
