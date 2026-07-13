import Foundation
import XCTest
@testable import RiftCore

final class EncounterBalanceSmokeTests: XCTestCase {
    func testChapterOneFixedEncounterSetAndOpeningActionsAreValid() throws {
        let catalog = try ContentLoader.load(from: projectDataDirectory())
        let skillsByID = Dictionary(uniqueKeysWithValues: catalog.skills.map { ($0.id, $0) })
        let encounters = catalog.encounters
        let expectedEncounterIDs: Set<String> = [
            "boar_intro",
            "road_bandit_ambush",
            "cave_vermin",
            "cave_miners",
            "rift_custodian",
            "river_taint_surge"
        ]

        XCTAssertEqual(Set(encounters.map(\.id)), expectedEncounterIDs)
        XCTAssertEqual(try chapterMapEncounterIDs(), expectedEncounterIDs)

        for encounter in encounters {
            XCTAssertFalse(encounter.enemies.isEmpty, encounter.id)
            try smokeOpeningAction(encounter, skillsByID: skillsByID)

            for enemy in encounter.enemies {
                XCTAssertLessThanOrEqual(enemy.stats.actionPoints, enemy.stats.maxActionPoints, enemy.id)
                for skillID in enemy.skillIDs {
                    let skill = try XCTUnwrap(skillsByID[skillID], "\(encounter.id):\(skillID)")
                    XCTAssertGreaterThan(skill.actionPointCost, 0, skillID)
                    XCTAssertLessThanOrEqual(skill.actionPointCost, enemy.stats.maxActionPoints, skillID)
                    XCTAssertGreaterThanOrEqual(skill.range, 0, skillID)
                }
            }
        }
    }

    private func smokeOpeningAction(
        _ encounter: EncounterDefinition,
        skillsByID: [String: SkillDefinition],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let enemy = try XCTUnwrap(encounter.enemies.first, file: file, line: line)
        let skillID = try XCTUnwrap(enemy.skillIDs.first, file: file, line: line)
        let skill = try XCTUnwrap(skillsByID[skillID], file: file, line: line)
        let hero = Actor(
            id: "smoke_hero",
            displayName: "测试冒险者",
            kind: .player,
            faction: .player,
            level: 1,
            stats: Stats(
                maxHealth: 36,
                health: 36,
                attack: 8,
                defense: 2,
                evasion: 0,
                magic: 1,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            classID: "warrior",
            skillIDs: ["slash"]
        )
        var engine = BattleEngine(state: BattleState(actors: [enemy, hero]))
        var random = SeededRandomSource(seed: 20260706)
        let context = TargetingContext(
            distance: min(max(skill.range, 0.1), 1.0),
            hasLineOfSight: true
        )

        do {
            _ = try engine.useSkill(
                actorID: enemy.id,
                targetID: hero.id,
                skill: skill,
                context: context,
                random: &random
            )
        } catch {
            XCTFail("\(encounter.id) opening action failed: \(error)", file: file, line: line)
        }
    }

    private func chapterMapEncounterIDs() throws -> Set<String> {
        let mapsURL = projectRoot().appending(path: "RiftExpedition/Resources/Maps/chapter1")
        let urls = FileManager.default.enumerator(at: mapsURL, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "tmx" } ?? []
        var ids: Set<String> = []

        for url in urls {
            let text = try String(contentsOf: url, encoding: .utf8)
            for line in text.components(separatedBy: .newlines) where line.contains("encounterId") {
                guard let value = line.components(separatedBy: "value=\"").dropFirst().first?.split(separator: "\"").first else {
                    continue
                }
                ids.insert(String(value))
            }
        }

        return ids
    }

    private func projectDataDirectory() -> URL {
        projectRoot().appending(path: "RiftExpedition/Resources/Data")
    }

    private func projectRoot() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
