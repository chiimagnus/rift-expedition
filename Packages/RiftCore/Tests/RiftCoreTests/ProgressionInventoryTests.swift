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

        try EquipmentRules.equip(
            itemID: "rusted_sword",
            on: &actor,
            inventory: inventory,
            items: [
                ItemDefinition(
                    id: "rusted_sword",
                    displayName: "锈剑",
                    kind: .equipment,
                    equipment: EquipmentDefinition(id: "rusted_sword", displayName: "锈剑", slot: .weapon)
                )
            ]
        )

        XCTAssertEqual(actor.equipment.weaponID, "rusted_sword")
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
}
