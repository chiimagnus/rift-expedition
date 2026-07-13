import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class PartyCreationViewModelTests: XCTestCase {
    func testBundledContentProvidesFourClasses() {
        let session = GameSessionViewModel()

        XCTAssertEqual(
            session.partyCreationViewModel.availableClasses.map(\.id),
            ["warrior", "archer", "mage", "rogue"]
        )
    }

    func testCannotStartWithFewerThanTwoSelections() throws {
        let viewModel = PartyCreationViewModel(classes: classFixtures, itemDefinitions: itemFixtures)

        viewModel.toggleSelection("warrior")

        XCTAssertFalse(viewModel.canStart)
        XCTAssertEqual(try viewModel.createParty(), [])
    }

    func testSelectedPartyCreatesActorsWithExpectedClassIDs() throws {
        let viewModel = PartyCreationViewModel(classes: classFixtures, itemDefinitions: itemFixtures)

        viewModel.toggleSelection("warrior")
        viewModel.toggleSelection("mage")

        let party = try viewModel.createParty()
        XCTAssertEqual(party.map(\.classID), ["warrior", "mage"])
        XCTAssertEqual(party[0].skillIDs, ["slash"])
        XCTAssertEqual(party[1].equipment.weaponID, "staff")
        XCTAssertEqual(party[0].stats.attack, 6)
        XCTAssertEqual(party[1].stats.magic, 3)
    }

    func testDoesNotAllowThirdClassSelection() {
        let viewModel = PartyCreationViewModel(classes: classFixtures, itemDefinitions: itemFixtures)

        viewModel.toggleSelection("warrior")
        viewModel.toggleSelection("mage")
        viewModel.toggleSelection("archer")

        XCTAssertEqual(viewModel.selectedClassIDs, ["warrior", "mage"])
    }

    private var classFixtures: [ClassDefinition] {
        [
            fixtureClass(id: "warrior", displayName: "战士", skill: "slash", weapon: "sword"),
            fixtureClass(id: "mage", displayName: "法师", skill: "spark", weapon: "staff"),
            fixtureClass(id: "archer", displayName: "弓箭手", skill: "shot", weapon: "bow")
        ]
    }

    private var itemFixtures: [ItemDefinition] {
        [
            equipmentItem(id: "sword", modifiers: StatModifiers(attack: 2)),
            equipmentItem(id: "staff", modifiers: StatModifiers(magic: 2)),
            equipmentItem(id: "bow", modifiers: StatModifiers(attack: 1))
        ]
    }

    private func equipmentItem(id: String, modifiers: StatModifiers) -> ItemDefinition {
        ItemDefinition(
            id: id,
            displayName: id,
            description: "测试物品说明",
            rarity: .common,
            kind: .equipment,
            equipment: EquipmentDefinition(
                id: id,
                displayName: id,
                slot: .weapon,
                modifiers: modifiers
            )
        )
    }

    private func fixtureClass(id: String, displayName: String, skill: String, weapon: String) -> ClassDefinition {
        ClassDefinition(
            id: id,
            displayName: displayName,
            title: "测试职业",
            combatRole: "测试定位",
            description: "测试职业说明",
            initialStats: Stats(
                maxHealth: 10,
                health: 10,
                attack: 4,
                defense: 3,
                evasion: 2,
                magic: 1,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            initialSkillIDs: [skill],
            defaultEquipment: EquipmentLoadout(weaponID: weapon)
        )
    }
}
