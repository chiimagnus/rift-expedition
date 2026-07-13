public enum EquipmentError: Error, Equatable, Sendable {
    case insufficientCopies(itemID: String, required: Int, available: Int)
    case unknownItem(String)
    case notEquipment(String)
    case invalidSlot(itemID: String, expected: EquipmentSlot, actual: EquipmentSlot)
}

public enum EquipmentRules {
    public static func equip(
        itemID: String,
        on actor: inout Actor,
        inventory: PartyInventory,
        equippedByOtherActors: Int,
        items: [ItemDefinition]
    ) throws {
        let available = inventory.count(of: itemID)
        let required = equippedByOtherActors + 1
        guard available >= required else {
            throw EquipmentError.insufficientCopies(
                itemID: itemID,
                required: required,
                available: available
            )
        }
        let equipment = try equipmentDefinition(itemID: itemID, items: items)
        let currentItemID = actor.equipment.itemID(in: equipment.slot)
        guard currentItemID != itemID else { return }

        if let currentItemID {
            let currentEquipment = try equipmentDefinition(itemID: currentItemID, items: items)
            guard currentEquipment.slot == equipment.slot else {
                throw EquipmentError.invalidSlot(
                    itemID: currentItemID,
                    expected: equipment.slot,
                    actual: currentEquipment.slot
                )
            }
            apply(currentEquipment.modifiers, multiplier: -1, to: &actor)
        }

        set(itemID: itemID, in: equipment.slot, on: &actor)
        apply(equipment.modifiers, multiplier: 1, to: &actor)
    }

    public static func applyEquippedModifiers(
        to actor: inout Actor,
        items: [ItemDefinition]
    ) throws {
        for (itemID, expectedSlot) in [
            (actor.equipment.weaponID, EquipmentSlot.weapon),
            (actor.equipment.armorID, EquipmentSlot.armor),
            (actor.equipment.accessoryID, EquipmentSlot.accessory)
        ] {
            guard let itemID else { continue }
            let equipment = try equipmentDefinition(itemID: itemID, items: items)
            guard equipment.slot == expectedSlot else {
                throw EquipmentError.invalidSlot(
                    itemID: itemID,
                    expected: expectedSlot,
                    actual: equipment.slot
                )
            }
            apply(equipment.modifiers, multiplier: 1, to: &actor)
        }
    }

    private static func equipmentDefinition(
        itemID: String,
        items: [ItemDefinition]
    ) throws -> EquipmentDefinition {
        guard let item = items.first(where: { $0.id == itemID }) else {
            throw EquipmentError.unknownItem(itemID)
        }
        guard item.kind == .equipment, let equipment = item.equipment else {
            throw EquipmentError.notEquipment(itemID)
        }
        return equipment
    }

    private static func set(itemID: String, in slot: EquipmentSlot, on actor: inout Actor) {
        switch slot {
        case .weapon:
            actor.equipment.weaponID = itemID
        case .armor:
            actor.equipment.armorID = itemID
        case .accessory:
            actor.equipment.accessoryID = itemID
        }
    }

    private static func apply(
        _ modifiers: StatModifiers,
        multiplier: Int,
        to actor: inout Actor
    ) {
        let wasAlive = actor.stats.health > 0
        let maxHealthDelta = modifiers.maxHealth * multiplier
        actor.stats.maxHealth += maxHealthDelta
        actor.stats.health += maxHealthDelta
        actor.stats.health = min(actor.stats.health, actor.stats.maxHealth)
        if wasAlive {
            actor.stats.health = max(1, actor.stats.health)
        } else {
            actor.stats.health = max(0, actor.stats.health)
        }
        actor.stats.attack += modifiers.attack * multiplier
        actor.stats.defense += modifiers.defense * multiplier
        actor.stats.evasion += modifiers.evasion * multiplier
        actor.stats.magic += modifiers.magic * multiplier
    }
}
