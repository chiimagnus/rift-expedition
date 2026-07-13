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
    func testQuestWithoutRequiredItemsIsRejected() {
        let json = #"{"id":"invalid","title":"Invalid","summary":"Missing requirements","startDialogID":"start","rewardItemIDs":[],"rewardSkillIDs":[]}"#

        XCTAssertThrowsError(try JSONDecoder().decode(QuestDefinition.self, from: Data(json.utf8)))
    }

    func testSkillDecodingRequiresEffectsField() throws {
        let json = """
        {
          "id": "missing_effects",
          "displayName": "缺少效果",
          "actionPointCost": 1,
          "range": 1.0,
          "target": "enemy",
          "affectsAllies": false,
          "canBeDodged": false
        }
        """

        XCTAssertThrowsError(try JSONDecoder().decode(SkillDefinition.self, from: Data(json.utf8)))
    }

    func testUnsupportedPointTargetFailsToDecode() throws {
        let json = """
        {
          "id": "ground_spell",
          "displayName": "地面法术",
          "actionPointCost": 1,
          "range": 3.0,
          "target": "point",
          "affectsAllies": false,
          "canBeDodged": false,
          "effects": [{"damage":{"_0":1}}]
        }
        """

        XCTAssertThrowsError(try JSONDecoder().decode(SkillDefinition.self, from: Data(json.utf8)))
    }

    func testUnsupportedMoveAndSummonEffectsFailToDecode() throws {
        let base = """
        {
          "id": "unsupported",
          "displayName": "未支持效果",
          "actionPointCost": 1,
          "range": 1.0,
          "target": "enemy",
          "affectsAllies": false,
          "canBeDodged": false,
          "effects": EFFECTS
        }
        """
        let payloads = [
            "[{\"move\":{\"distance\":2.0}}]",
            "[{\"summon\":{\"actorID\":\"wolf\"}}]"
        ]

        for payload in payloads {
            let json = base.replacing("EFFECTS", with: payload)
            XCTAssertThrowsError(try JSONDecoder().decode(SkillDefinition.self, from: Data(json.utf8)))
        }
    }

}
