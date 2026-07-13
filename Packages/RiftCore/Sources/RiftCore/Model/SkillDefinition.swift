public enum SkillTarget: String, Codable, CaseIterable, Sendable {
    case selfOnly
    case ally
    case enemy
}

public struct SkillDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var description: String?
    public var actionPointCost: Int
    public var range: Double
    public var target: SkillTarget
    public var affectsAllies: Bool
    public var canBeDodged: Bool
    public var effects: [SkillEffect]

    public init(
        id: String,
        displayName: String,
        description: String? = nil,
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

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case description
        case actionPointCost
        case range
        case target
        case affectsAllies
        case canBeDodged
        case effects
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.actionPointCost = try container.decode(Int.self, forKey: .actionPointCost)
        self.range = try container.decode(Double.self, forKey: .range)
        self.target = try container.decode(SkillTarget.self, forKey: .target)
        self.affectsAllies = try container.decode(Bool.self, forKey: .affectsAllies)
        self.canBeDodged = try container.decode(Bool.self, forKey: .canBeDodged)
        self.effects = try container.decode([SkillEffect].self, forKey: .effects)
    }
}
