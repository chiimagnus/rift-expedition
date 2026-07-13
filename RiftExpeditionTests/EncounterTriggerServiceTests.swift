import CoreGraphics
import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class EncounterTriggerServiceTests: XCTestCase {
    func testBundledEncounterDefinitionsDecode() throws {
        let encounters = try EncounterTriggerService.loadDefinitions()

        XCTAssertEqual(encounters.first?.id, "boar_intro")
        XCTAssertEqual(encounters.first?.enemies.first?.displayName, "受惊野猪")
    }

    func testDuplicateEncounterIDsAreRejected() {
        XCTAssertThrowsError(try EncounterTriggerService.validateDefinitions([encounter, encounter])) { error in
            XCTAssertEqual(error as? EncounterDefinitionLoadingError, .duplicateEncounterID("boar_intro"))
        }
    }

    func testDuplicateEnemyIDsAreRejected() {
        let invalid = EncounterDefinition(
            id: "duplicate_enemy",
            displayName: "重复敌人",
            enemies: [enemy, enemy]
        )

        XCTAssertThrowsError(try EncounterTriggerService.validateDefinitions([invalid])) { error in
            XCTAssertEqual(
                error as? EncounterDefinitionLoadingError,
                .duplicateEnemyID(encounterID: "duplicate_enemy", actorID: "boar")
            )
        }
    }

    func testEmptyEnemyRosterIsRejected() {
        let invalid = EncounterDefinition(id: "empty", displayName: "空遭遇", enemies: [])

        XCTAssertThrowsError(try EncounterTriggerService.validateDefinitions([invalid])) { error in
            XCTAssertEqual(error as? EncounterDefinitionLoadingError, .emptyEnemyRoster(encounterID: "empty"))
        }
    }

    func testNonHostileEnemyIsRejected() {
        var invalidEnemy = enemy
        invalidEnemy.faction = .player
        let invalid = EncounterDefinition(id: "friendly", displayName: "友军", enemies: [invalidEnemy])

        XCTAssertThrowsError(try EncounterTriggerService.validateDefinitions([invalid])) { error in
            XCTAssertEqual(
                error as? EncounterDefinitionLoadingError,
                .invalidEnemyFaction(encounterID: "friendly", actorID: "boar")
            )
        }
    }

    func testEnteringTriggerStartsBattleOnce() throws {
        var service = try EncounterTriggerService(
            triggers: [
                MapEncounterTrigger(
                    tiledID: 1,
                    encounterID: "boar_intro",
                    frame: CGRect(x: 100, y: 100, width: 40, height: 40),
                    radius: 10
                )
            ],
            encounters: [encounter]
        )

        XCTAssertNil(service.pendingEncounter(at: CGPoint(x: 20, y: 20)))
        let pending = service.pendingEncounter(at: CGPoint(x: 110, y: 110))
        XCTAssertEqual(pending?.definition.id, "boar_intro")
        XCTAssertTrue(service.triggeredTiledIDs.isEmpty)

        service.markTriggered(tiledID: try XCTUnwrap(pending?.trigger.tiledID))
        XCTAssertNil(service.pendingEncounter(at: CGPoint(x: 110, y: 110)))
    }

    func testMissingEncounterDefinitionDoesNotConsumeTrigger() throws {
        var service = try EncounterTriggerService(
            triggers: [
                MapEncounterTrigger(
                    tiledID: 99,
                    encounterID: "missing_encounter",
                    frame: CGRect(x: 100, y: 100, width: 40, height: 40),
                    radius: 10
                )
            ],
            encounters: []
        )

        XCTAssertNil(service.pendingEncounter(at: CGPoint(x: 110, y: 110)))
        XCTAssertTrue(service.triggeredTiledIDs.isEmpty)
        XCTAssertNil(service.pendingEncounter(at: CGPoint(x: 110, y: 110)))
        XCTAssertTrue(service.triggeredTiledIDs.isEmpty)
    }

    func testMissingDefinitionDoesNotShadowOverlappingValidTrigger() throws {
        var service = try EncounterTriggerService(
            triggers: [
                MapEncounterTrigger(
                    tiledID: 98,
                    encounterID: "missing_encounter",
                    frame: CGRect(x: 100, y: 100, width: 40, height: 40),
                    radius: 10
                ),
                MapEncounterTrigger(
                    tiledID: 99,
                    encounterID: "boar_intro",
                    frame: CGRect(x: 100, y: 100, width: 40, height: 40),
                    radius: 10
                )
            ],
            encounters: [encounter]
        )

        let pending = service.pendingEncounter(at: CGPoint(x: 110, y: 110))

        XCTAssertEqual(pending?.definition.id, "boar_intro")
        XCTAssertEqual(pending?.trigger.tiledID, 99)
        XCTAssertTrue(service.triggeredTiledIDs.isEmpty)
    }

    func testSameEncounterDefinitionCanBeUsedByTwoMapObjects() throws {
        var service = try EncounterTriggerService(
            triggers: [
                MapEncounterTrigger(
                    tiledID: 41,
                    encounterID: "boar_intro",
                    frame: CGRect(x: 100, y: 100, width: 40, height: 40),
                    radius: 10
                ),
                MapEncounterTrigger(
                    tiledID: 42,
                    encounterID: "boar_intro",
                    frame: CGRect(x: 200, y: 100, width: 40, height: 40),
                    radius: 10
                )
            ],
            encounters: [encounter]
        )

        XCTAssertEqual(service.pendingEncounter(at: CGPoint(x: 110, y: 110))?.definition.id, "boar_intro")
        service.markTriggered(tiledID: 41)
        XCTAssertEqual(service.pendingEncounter(at: CGPoint(x: 210, y: 110))?.definition.id, "boar_intro")
        service.markTriggered(tiledID: 42)
        XCTAssertEqual(service.triggeredTiledIDs, [41, 42])
    }

    func testPendingEncounterIsNotConsumedUntilExplicitlyMarked() throws {
        var service = try EncounterTriggerService(
            triggers: [
                MapEncounterTrigger(
                    tiledID: 41,
                    encounterID: "boar_intro",
                    frame: CGRect(x: 100, y: 100, width: 40, height: 40),
                    radius: 10
                )
            ],
            encounters: [encounter]
        )

        XCTAssertNotNil(service.pendingEncounter(at: CGPoint(x: 110, y: 110)))
        XCTAssertNotNil(service.pendingEncounter(at: CGPoint(x: 110, y: 110)))
        XCTAssertTrue(service.triggeredTiledIDs.isEmpty)

        service.markTriggered(tiledID: 41)
        XCTAssertNil(service.pendingEncounter(at: CGPoint(x: 110, y: 110)))
    }

    func testPretriggeredTiledObjectDoesNotStartAgain() throws {
        var service = try EncounterTriggerService(
            triggers: [
                MapEncounterTrigger(
                    tiledID: 41,
                    encounterID: "boar_intro",
                    frame: CGRect(x: 100, y: 100, width: 40, height: 40),
                    radius: 10
                )
            ],
            encounters: [encounter],
            triggeredTiledIDs: [41]
        )

        XCTAssertNil(service.pendingEncounter(at: CGPoint(x: 110, y: 110)))
        XCTAssertEqual(service.triggeredTiledIDs, [41])
    }

    func testChapterMapMetadataReadsEncounterTrigger() throws {
        let metadata = try TiledMapLoader.loadMetadata(url: villageOutskirtsURL(), areaID: "village_outskirts")

        XCTAssertEqual(metadata.encounterTriggers.first?.encounterID, "boar_intro")
    }

    private var encounter: EncounterDefinition {
        EncounterDefinition(id: "boar_intro", displayName: "受惊野猪", enemies: [enemy])
    }

    private var enemy: Actor {
        Actor(
            id: "boar",
            displayName: "受惊野猪",
            kind: .animal,
            faction: .animal,
            level: 1,
            stats: Stats(
                maxHealth: 10,
                health: 10,
                attack: 4,
                defense: 1,
                evasion: 1,
                magic: 0,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            skillIDs: ["boar_bite"]
        )
    }

    private func villageOutskirtsURL() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "RiftExpedition/Resources/Maps/chapter1/village_outskirts.tmx")
    }
}
