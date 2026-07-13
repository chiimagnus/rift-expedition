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
            title: "测试职业",
            combatRole: "测试定位",
            description: "测试职业说明",
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
            description: "测试技能说明",
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
    func testQuestMissingAnyStrictMetadataFieldIsRejected() throws {
        let complete: [String: Any] = [
            "id": "strict",
            "chapterID": "chapter1",
            "title": "严格任务",
            "summary": "完整字段",
            "isMainQuest": false,
            "locationHint": "测试地点",
            "objectives": ["完成测试目标"],
            "startDialogID": "start",
            "turnInDialogID": "turn_in",
            "requiredItemIDs": [],
            "rewardItemIDs": [],
            "rewardSkillIDs": []
        ]
        for field in [
            "chapterID", "title", "summary", "isMainQuest", "locationHint", "objectives",
            "startDialogID", "turnInDialogID", "requiredItemIDs", "rewardItemIDs", "rewardSkillIDs"
        ] {
            var object = complete
            object.removeValue(forKey: field)
            let data = try JSONSerialization.data(withJSONObject: object)
            XCTAssertThrowsError(try JSONDecoder().decode(QuestDefinition.self, from: data), field)
        }
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
          "description": "测试技能说明",
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
          "description": "测试技能说明",
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
          "description": "测试技能说明",
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

    func testDisplayMetadataFieldsAreRequired() throws {
        let stats = Stats(
            maxHealth: 10,
            health: 10,
            attack: 1,
            defense: 1,
            evasion: 1,
            magic: 1,
            maxActionPoints: 4,
            actionPoints: 4
        )
        let classDefinition = ClassDefinition(
            id: "warrior",
            displayName: "战士",
            title: "灰烬先锋",
            combatRole: "前排防御",
            description: "在裂隙前线承受冲击。",
            initialStats: stats,
            initialSkillIDs: ["slash"],
            defaultEquipment: EquipmentLoadout()
        )
        let skill = SkillDefinition(
            id: "slash",
            displayName: "斩击",
            description: "对敌人造成伤害。",
            actionPointCost: 1,
            range: 1,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: true,
            effects: [.damage(1)]
        )
        let item = ItemDefinition(
            id: "ledger",
            displayName: "矿账册",
            description: "记录非法采掘活动。",
            rarity: .common,
            kind: .quest
        )

        try assertMissingFieldsFailToDecode(classDefinition, fields: ["title", "combatRole", "description"])
        try assertMissingFieldsFailToDecode(skill, fields: ["description"])
        try assertMissingFieldsFailToDecode(item, fields: ["description", "rarity"])
    }

    private func assertMissingFieldsFailToDecode<T: Codable>(
        _ value: T,
        fields: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let encoded = try JSONEncoder().encode(value)
        guard let original = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
            return XCTFail("Expected a top-level JSON object", file: file, line: line)
        }

        for field in fields {
            var object = original
            object.removeValue(forKey: field)
            let data = try JSONSerialization.data(withJSONObject: object)
            XCTAssertThrowsError(try JSONDecoder().decode(T.self, from: data), field, file: file, line: line)
        }
    }

}
