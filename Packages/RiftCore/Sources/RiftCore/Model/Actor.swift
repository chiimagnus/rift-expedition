public enum ActorKind: String, Codable, CaseIterable, Sendable {
    case player
    case npc
    case humanEnemy
    case animal
    case monster
}

public struct Actor: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var kind: ActorKind
    public var faction: Faction
    public var level: Int
    public var experience: Int
    public var unspentAttributePoints: Int
    public var stats: Stats
    public var classID: String?
    public var skillIDs: [String]
    public var equipment: EquipmentLoadout
    public var statuses: [StatusEffect]

    public init(
        id: String,
        displayName: String,
        kind: ActorKind,
        faction: Faction,
        level: Int,
        experience: Int = 0,
        unspentAttributePoints: Int = 0,
        stats: Stats,
        classID: String? = nil,
        skillIDs: [String],
        equipment: EquipmentLoadout = EquipmentLoadout(),
        statuses: [StatusEffect] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.faction = faction
        self.level = level
        self.experience = experience
        self.unspentAttributePoints = unspentAttributePoints
        self.stats = stats
        self.classID = classID
        self.skillIDs = skillIDs
        self.equipment = equipment
        self.statuses = statuses
    }
}
