import RiftCore
import XCTest
@testable import RiftExpedition

final class ActorVisualIDResolverTests: XCTestCase {
    func testPlayerClassIDsResolveToVisualIDs() {
        XCTAssertEqual(visualID(kind: .player, classID: "warrior"), "actor_warrior")
        XCTAssertEqual(visualID(kind: .player, classID: "archer"), "actor_archer")
        XCTAssertEqual(visualID(kind: .player, classID: "mage"), "actor_mage")
        XCTAssertEqual(visualID(kind: .player, classID: "rogue"), "actor_rogue")
        XCTAssertEqual(visualID(kind: .player), "actor_warrior")
    }

    func testNPCIDsResolveToVisualIDs() {
        XCTAssertEqual(visualID(id: "mayor", kind: .npc), "npc_mayor")
        XCTAssertEqual(visualID(id: "elder", kind: .npc), "npc_mayor")
        XCTAssertEqual(visualID(id: "fiance", kind: .npc), "npc_fiance")
        XCTAssertEqual(visualID(id: "gate_guard", kind: .npc), "npc_gate_guard")
        XCTAssertEqual(visualID(id: "healer", kind: .npc), "npc_healer")
        XCTAssertEqual(visualID(id: "unknown", kind: .npc), "npc_mayor")
    }

    func testEnemyIDsResolveToVisualIDs() {
        XCTAssertEqual(visualID(kind: .humanEnemy, classID: "warrior", level: 1), "enemy_human_melee")
        XCTAssertEqual(visualID(kind: .humanEnemy, classID: "archer", level: 1), "enemy_human_ranged")
        XCTAssertEqual(visualID(kind: .humanEnemy, classID: "archer", level: 4), "enemy_human_elite")
        XCTAssertEqual(visualID(kind: .animal), "enemy_beast_animal")
        XCTAssertEqual(visualID(kind: .monster, level: 2), "enemy_beast_tainted")
        XCTAssertEqual(visualID(kind: .monster, level: 3), "enemy_beast_rift")
    }

    func testAllTargetVisualIDsAreCovered() {
        let visualIDs = Set([
            visualID(kind: .player, classID: "warrior"),
            visualID(kind: .player, classID: "archer"),
            visualID(kind: .player, classID: "mage"),
            visualID(kind: .player, classID: "rogue"),
            visualID(id: "mayor", kind: .npc),
            visualID(id: "fiance", kind: .npc),
            visualID(id: "gate_guard", kind: .npc),
            visualID(id: "healer", kind: .npc),
            visualID(kind: .humanEnemy, classID: "warrior"),
            visualID(kind: .humanEnemy, classID: "archer"),
            visualID(kind: .humanEnemy, level: 4),
            visualID(kind: .animal),
            visualID(kind: .monster, level: 2),
            visualID(kind: .monster, level: 3)
        ])

        XCTAssertEqual(visualIDs, [
            "actor_warrior",
            "actor_archer",
            "actor_mage",
            "actor_rogue",
            "npc_mayor",
            "npc_fiance",
            "npc_gate_guard",
            "npc_healer",
            "enemy_human_melee",
            "enemy_human_ranged",
            "enemy_human_elite",
            "enemy_beast_animal",
            "enemy_beast_tainted",
            "enemy_beast_rift"
        ])
    }

    private func visualID(
        id: String = "actor",
        kind: ActorKind,
        classID: String? = nil,
        level: Int = 1
    ) -> String {
        ActorVisualIDResolver.visualID(for: Actor(
            id: id,
            displayName: id,
            kind: kind,
            faction: .player,
            level: level,
            stats: Stats(
                maxHealth: 1,
                health: 1,
                attack: 1,
                defense: 0,
                evasion: 0,
                magic: 0,
                maxActionPoints: 1,
                actionPoints: 1
            ),
            classID: classID,
            skillIDs: []
        ))
    }
}
