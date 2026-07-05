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
    public var stats: Stats
    public var classID: String?
    public var skillIDs: [String]
    public var equipment: EquipmentLoadout

    public init(
        id: String,
        displayName: String,
        kind: ActorKind,
        faction: Faction,
        level: Int,
        stats: Stats,
        classID: String? = nil,
        skillIDs: [String],
        equipment: EquipmentLoadout = EquipmentLoadout()
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.faction = faction
        self.level = level
        self.stats = stats
        self.classID = classID
        self.skillIDs = skillIDs
        self.equipment = equipment
    }
}
