import XCTest
@testable import RiftCore

final class ProgressionInventoryTests: XCTestCase {
    func testLevelUpGrantsAttributePoints() {
        var actor = makeActor()

        let result = ExperienceCurve.grantExperience(100, to: &actor)

        XCTAssertEqual(result, LevelUpResult(levelsGained: 1, attributePointsGained: 2))
        XCTAssertEqual(actor.level, 2)
        XCTAssertEqual(actor.unspentAttributePoints, 2)
    }

    func testInvalidAttributeAllocationFails() {
        var actor = makeActor(unspentAttributePoints: 1)

        XCTAssertThrowsError(try AttributePoints.allocate(2, to: .attack, actor: &actor)) { error in
            XCTAssertEqual(error as? AttributePointError, .insufficientPoints(required: 2, available: 1))
        }
    }

    func testSharedInventoryItemCanEquipSpecificActor() throws {
        var inventory = PartyInventory()
        inventory.addItem(id: "rusted_sword")
        var actor = makeActor()
        let sword = ItemDefinition(
            id: "rusted_sword",
            displayName: "锈剑",
            description: "测试物品说明",
            rarity: .common,
            kind: .equipment,
            equipment: EquipmentDefinition(
                id: "rusted_sword",
                displayName: "锈剑",
                slot: .weapon,
                modifiers: StatModifiers(attack: 2)
            )
        )

        try EquipmentRules.equip(
            itemID: "rusted_sword",
            on: &actor,
            inventory: inventory,
            equippedByOtherActors: 0,
            items: [sword]
        )

        XCTAssertEqual(actor.equipment.weaponID, "rusted_sword")
        XCTAssertEqual(actor.stats.attack, 7)
    }

    func testReplacingEquipmentRemovesOldModifiersBeforeAddingNewOnes() throws {
        let oldSword = equipmentItem(id: "old_sword", slot: .weapon, modifiers: StatModifiers(attack: 2))
        let newSword = equipmentItem(id: "new_sword", slot: .weapon, modifiers: StatModifiers(attack: 4))
        let inventory = try PartyInventory(itemCounts: ["old_sword": 1, "new_sword": 1])
        var actor = makeActor()
        actor.equipment.weaponID = "old_sword"
        try EquipmentRules.applyEquippedModifiers(to: &actor, items: [oldSword, newSword])

        try EquipmentRules.equip(
            itemID: "new_sword",
            on: &actor,
            inventory: inventory,
            equippedByOtherActors: 0,
            items: [oldSword, newSword]
        )

        XCTAssertEqual(actor.equipment.weaponID, "new_sword")
        XCTAssertEqual(actor.stats.attack, 9)
    }

    func testInitialLoadoutModifiersAdjustHealthAndCombatStats() throws {
        let armor = equipmentItem(
            id: "armor",
            slot: .armor,
            modifiers: StatModifiers(maxHealth: 4, defense: 2)
        )
        var actor = makeActor()
        actor.equipment.armorID = "armor"

        try EquipmentRules.applyEquippedModifiers(to: &actor, items: [armor])

        XCTAssertEqual(actor.stats.maxHealth, 24)
        XCTAssertEqual(actor.stats.health, 24)
        XCTAssertEqual(actor.stats.defense, 4)
    }

    func testEquippingRequiresASeparateInventoryCopyForEachActor() throws {
        let inventory = try PartyInventory(itemCounts: ["rusted_sword": 1])
        var actor = makeActor()

        XCTAssertThrowsError(
            try EquipmentRules.equip(
                itemID: "rusted_sword",
                on: &actor,
                inventory: inventory,
                equippedByOtherActors: 1,
                items: [
                    ItemDefinition(
                        id: "rusted_sword",
                        displayName: "锈剑",
                        description: "测试物品说明",
                        rarity: .common,
                        kind: .equipment,
                        equipment: EquipmentDefinition(
                            id: "rusted_sword",
                            displayName: "锈剑",
                            slot: .weapon
                        )
                    )
                ]
            )
        ) { error in
            XCTAssertEqual(
                error as? EquipmentError,
                .insufficientCopies(itemID: "rusted_sword", required: 2, available: 1)
            )
        }
    }

    private func makeActor(unspentAttributePoints: Int = 0) -> Actor {
        Actor(
            id: "hero",
            displayName: "队员",
            kind: .player,
            faction: .player,
            level: 1,
            unspentAttributePoints: unspentAttributePoints,
            stats: Stats(
                maxHealth: 20,
                health: 20,
                attack: 5,
                defense: 2,
                evasion: 3,
                magic: 1,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            skillIDs: []
        )
    }

    private func equipmentItem(
        id: String,
        slot: EquipmentSlot,
        modifiers: StatModifiers
    ) -> ItemDefinition {
        ItemDefinition(
            id: id,
            displayName: id,
            description: "测试物品说明",
            rarity: .common,
            kind: .equipment,
            equipment: EquipmentDefinition(
                id: id,
                displayName: id,
                slot: slot,
                modifiers: modifiers
            )
        )
    }
}
