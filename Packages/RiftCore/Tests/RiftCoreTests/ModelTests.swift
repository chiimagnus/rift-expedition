import XCTest
@testable import RiftCore

final class ModelTests: XCTestCase {
    func testActorRoundTripsAsUnifiedEntity() throws {
        let actor = Actor(
            id: "wolf_alpha",
            displayName: "头狼",
            kind: .animal,
            faction: .animal,
            level: 2,
            stats: Stats(
                maxHealth: 24,
                health: 24,
                attack: 7,
                defense: 2,
                evasion: 8,
                magic: 0,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            skillIDs: ["bite"]
        )

        let data = try JSONEncoder().encode(actor)
        let decoded = try JSONDecoder().decode(Actor.self, from: data)

        XCTAssertEqual(decoded, actor)
    }

    func testClassOnlyReferencesSkillsAndEquipment() {
        let warrior = ClassDefinition(
            id: "warrior",
            displayName: "战士",
            initialStats: Stats(
                maxHealth: 36,
                health: 36,
                attack: 8,
                defense: 6,
                evasion: 2,
                magic: 1,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            initialSkillIDs: ["slash", "guard", "charge"],
            defaultEquipment: EquipmentLoadout(weaponID: "rusted_sword", armorID: "padded_armor")
        )

        XCTAssertEqual(warrior.initialSkillIDs, ["slash", "guard", "charge"])
        XCTAssertEqual(warrior.defaultEquipment.weaponID, "rusted_sword")
    }

    func testSkillAndEquipmentAreIndependentDefinitions() {
        let skill = SkillDefinition(
            id: "firebolt",
            displayName: "火焰箭",
            actionPointCost: 2,
            range: 8,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: false
        )
        let weapon = EquipmentDefinition(
            id: "apprentice_staff",
            displayName: "学徒法杖",
            slot: .weapon,
            modifiers: StatModifiers(magic: 2)
        )

        XCTAssertEqual(skill.id, "firebolt")
        XCTAssertEqual(weapon.slot, .weapon)
    }
    func testLegacyQuestWithoutRequiredItemsDecodesWithEmptyRequirement() throws {
        let json = #"{"id":"legacy","title":"Legacy","summary":"Old save data","startDialogID":"start","rewardItemIDs":[],"rewardSkillIDs":[]}"#
        let quest = try JSONDecoder().decode(QuestDefinition.self, from: Data(json.utf8))

        XCTAssertEqual(quest.requiredItemIDs, [])
    }

}
