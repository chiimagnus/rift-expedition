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
        XCTAssertEqual(viewModel.party.first?.stats.attack, 7)
        XCTAssertEqual(viewModel.statusText, "队员 已装备 锈剑。")
    }

    func testSameInventoryCopyCannotBeEquippedByTwoActors() {
        var inventory = PartyInventory()
        inventory.addItem(id: "rusted_sword")
        var firstActor = actor(id: "hero", displayName: "队员")
        firstActor.equipment.weaponID = "rusted_sword"
        let viewModel = InventoryViewModel(
            party: [firstActor, actor(id: "partner", displayName: "同伴")],
            inventory: inventory,
            itemDefinitions: [rustedSword]
        )
        viewModel.selectActor(id: "partner")

        viewModel.equip(itemID: "rusted_sword")

        XCTAssertNil(viewModel.party[1].equipment.weaponID)
        XCTAssertEqual(viewModel.statusText, "装备数量不足：需要 2，背包中有 1。")
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
    }

    private func actor(
        id: String = "hero",
        displayName: String = "队员",
        unspentAttributePoints: Int = 0
    ) -> Actor {
        Actor(
            id: id,
            displayName: displayName,
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
