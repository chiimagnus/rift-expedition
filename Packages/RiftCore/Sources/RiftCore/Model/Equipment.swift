public enum EquipmentSlot: String, Codable, CaseIterable, Sendable {
    case weapon
    case armor
    case accessory
}

public struct StatModifiers: Codable, Equatable, Sendable {
    public var maxHealth: Int
    public var attack: Int
    public var defense: Int
    public var evasion: Int
    public var magic: Int

    public init(maxHealth: Int = 0, attack: Int = 0, defense: Int = 0, evasion: Int = 0, magic: Int = 0) {
        self.maxHealth = maxHealth
        self.attack = attack
        self.defense = defense
        self.evasion = evasion
        self.magic = magic
    }
}

public struct EquipmentDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var slot: EquipmentSlot
    public var modifiers: StatModifiers

    public init(id: String, displayName: String, slot: EquipmentSlot, modifiers: StatModifiers = StatModifiers()) {
        self.id = id
        self.displayName = displayName
        self.slot = slot
        self.modifiers = modifiers
    }
}

public struct EquipmentLoadout: Codable, Equatable, Sendable {
    public var weaponID: String?
    public var armorID: String?
    public var accessoryID: String?

    public init(weaponID: String? = nil, armorID: String? = nil, accessoryID: String? = nil) {
        self.weaponID = weaponID
        self.armorID = armorID
        self.accessoryID = accessoryID
    }

    public func itemID(in slot: EquipmentSlot) -> String? {
        switch slot {
        case .weapon:
            weaponID
        case .armor:
            armorID
        case .accessory:
            accessoryID
        }
    }
}

public enum ItemKind: String, Codable, CaseIterable, Sendable {
    case equipment
    case consumable
    case quest
}

public struct ItemDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var kind: ItemKind
    public var equipment: EquipmentDefinition?

    public init(id: String, displayName: String, kind: ItemKind, equipment: EquipmentDefinition? = nil) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.equipment = equipment
    }
}
