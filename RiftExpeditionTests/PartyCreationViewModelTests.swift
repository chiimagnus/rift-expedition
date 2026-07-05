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

    func testCannotStartWithFewerThanTwoSelections() {
        let viewModel = PartyCreationViewModel(classes: classFixtures)

        viewModel.toggleSelection("warrior")

        XCTAssertFalse(viewModel.canStart)
        XCTAssertEqual(viewModel.createParty(), [])
    }

    func testSelectedPartyCreatesActorsWithExpectedClassIDs() throws {
        let viewModel = PartyCreationViewModel(classes: classFixtures)

        viewModel.toggleSelection("warrior")
        viewModel.toggleSelection("mage")

        let party = viewModel.createParty()
        XCTAssertEqual(party.map(\.classID), ["warrior", "mage"])
        XCTAssertEqual(party[0].skillIDs, ["slash"])
        XCTAssertEqual(party[1].equipment.weaponID, "staff")
    }

    func testDoesNotAllowThirdClassSelection() {
        let viewModel = PartyCreationViewModel(classes: classFixtures)

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

    private func fixtureClass(id: String, displayName: String, skill: String, weapon: String) -> ClassDefinition {
        ClassDefinition(
            id: id,
            displayName: displayName,
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
