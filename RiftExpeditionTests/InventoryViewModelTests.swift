import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class InventoryViewModelTests: XCTestCase {
    func testEquippingItemChangesActorEquipment() {
        var inventory = PartyInventory()
        inventory.addItem(id: "rusted_sword")
        let viewModel = InventoryViewModel(
            party: [actor()],
            inventory: inventory,
            itemDefinitions: [rustedSword]
        )

        viewModel.equip(itemID: "rusted_sword")

        XCTAssertEqual(viewModel.party.first?.equipment.weaponID, "rusted_sword")
        XCTAssertEqual(viewModel.statusText, "队员 已装备 锈剑。")
    }

    func testSpendingAttributePointDecrementsAvailablePoints() {
        let viewModel = InventoryViewModel(
            party: [actor(unspentAttributePoints: 2)],
            inventory: PartyInventory(),
            itemDefinitions: []
        )

        viewModel.allocate(.attack)

        XCTAssertEqual(viewModel.party.first?.unspentAttributePoints, 1)
        XCTAssertEqual(viewModel.party.first?.stats.attack, 6)
    }

    private var rustedSword: ItemDefinition {
        ItemDefinition(
            id: "rusted_sword",
            displayName: "锈剑",
            kind: .equipment,
            equipment: EquipmentDefinition(id: "rusted_sword", displayName: "锈剑", slot: .weapon)
        )
    }

    private func actor(unspentAttributePoints: Int = 0) -> Actor {
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
