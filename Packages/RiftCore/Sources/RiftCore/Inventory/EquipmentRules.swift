public enum EquipmentError: Error, Equatable, Sendable {
    case itemNotInInventory(String)
    case unknownItem(String)
    case notEquipment(String)
}

public enum EquipmentRules {
    public static func equip(
        itemID: String,
        on actor: inout Actor,
        inventory: PartyInventory,
        items: [ItemDefinition]
    ) throws {
        guard inventory.count(of: itemID) > 0 else {
            throw EquipmentError.itemNotInInventory(itemID)
        }
        guard let item = items.first(where: { $0.id == itemID }) else {
            throw EquipmentError.unknownItem(itemID)
        }
        guard item.kind == .equipment, let equipment = item.equipment else {
            throw EquipmentError.notEquipment(itemID)
        }

        switch equipment.slot {
        case .weapon:
            actor.equipment.weaponID = itemID
        case .armor:
            actor.equipment.armorID = itemID
        case .accessory:
            actor.equipment.accessoryID = itemID
        }
    }
}
