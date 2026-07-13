import CoreGraphics
import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class EncounterTriggerServiceTests: XCTestCase {
    func testBundledEncounterDefinitionsDecode() {
        let encounters = EncounterTriggerService.loadDefinitions()

        XCTAssertEqual(encounters.first?.id, "boar_intro")
        XCTAssertEqual(encounters.first?.enemies.first?.displayName, "受惊野猪")
    }

    func testEnteringTriggerStartsBattleOnce() throws {
        var service = EncounterTriggerService(
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

        XCTAssertNil(service.encounter(at: CGPoint(x: 20, y: 20)))
        XCTAssertEqual(service.encounter(at: CGPoint(x: 110, y: 110))?.id, "boar_intro")
        XCTAssertNil(service.encounter(at: CGPoint(x: 110, y: 110)))
    }

    func testPretriggeredTiledObjectDoesNotStartAgain() {
        var service = EncounterTriggerService(
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

        XCTAssertNil(service.encounter(at: CGPoint(x: 110, y: 110)))
        XCTAssertEqual(service.triggeredTiledIDs, [41])
    }

    func testVerticalSliceMetadataReadsEncounterTrigger() throws {
        let metadata = try TiledMapLoader.loadMetadata(url: verticalSliceURL(), areaID: "vertical_slice")

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

    private func verticalSliceURL() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "RiftExpedition/Resources/Maps/vertical_slice.tmx")
    }
}
