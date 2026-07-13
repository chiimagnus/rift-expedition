public enum SkillTarget: String, Codable, CaseIterable, Sendable {
    case selfOnly
    case ally
    case enemy
}

public struct SkillDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var description: String
    public var actionPointCost: Int
    public var range: Double
    public var target: SkillTarget
    public var affectsAllies: Bool
    public var canBeDodged: Bool
    public var effects: [SkillEffect]

    public init(
        id: String,
        displayName: String,
        description: String,
        actionPointCost: Int,
        range: Double,
        target: SkillTarget,
        affectsAllies: Bool,
        canBeDodged: Bool,
        effects: [SkillEffect] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.actionPointCost = actionPointCost
        self.range = range
        self.target = target
        self.affectsAllies = affectsAllies
        self.canBeDodged = canBeDodged
        self.effects = effects
    }

}
