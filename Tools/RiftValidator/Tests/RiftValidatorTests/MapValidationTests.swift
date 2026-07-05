import XCTest
@testable import RiftValidator

final class MapValidationTests: XCTestCase {
    func testValidFixturePasses() throws {
        let result = try MapValidator.validate(url: fixture("valid-map"))

        XCTAssertTrue(result.isValid, result.reportMarkdown())
    }

    func testMissingSpawnLayerFailsWithReadableError() throws {
        let result = try MapValidator.validate(url: fixture("invalid-map-missing-spawn"))

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.reportMarkdown().contains("Missing object layer: spawn"))
    }

    func testCrossAreaExitCanTargetSpawnInAnotherMap() throws {
        let results = try MapValidator.validate(urls: [
            fixture("cross-a"),
            fixture("cross-b")
        ])

        XCTAssertTrue(results.allSatisfy(\.isValid), results.map { $0.reportMarkdown() }.joined(separator: "\n"))
    }

    func testWorldGraphDetectsDisconnectedArea() {
        let mapA = map("a", spawns: ["start"])
        let mapB = map("b", spawns: ["entry"])
        let mapC = map("c", spawns: ["entry"])
        let graph = ChapterWorldGraph(
            id: "test",
            title: "测试世界",
            startAreaId: "a",
            startSpawnId: "start",
            areas: [
                ChapterWorldArea(
                    id: "a",
                    displayName: "A",
                    biome: "test",
                    mapPath: "Maps/a.tmx",
                    exits: [ChapterWorldExit(id: "to_b", targetAreaId: "b", targetSpawnId: "entry")]
                ),
                ChapterWorldArea(id: "b", displayName: "B", biome: "test", mapPath: "Maps/b.tmx", exits: []),
                ChapterWorldArea(id: "c", displayName: "C", biome: "test", mapPath: "Maps/c.tmx", exits: [])
            ]
        )

        let result = WorldGraphValidator.validate(graph, maps: [mapA, mapB, mapC])

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.reportMarkdown().contains("World area is disconnected from start: c"))
    }

    private func fixture(_ name: String) throws -> URL {
        try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "tmx", subdirectory: "Fixtures"))
    }

    private func map(_ areaID: String, spawns: [String]) -> TiledMap {
        TiledMap(
            areaID: areaID,
            width: 320,
            height: 320,
            objectGroups: [
                "spawn": spawns.enumerated().map { index, spawnID in
                    TiledObject(
                        tiledID: index + 1,
                        name: nil,
                        type: nil,
                        x: 32,
                        y: 32,
                        width: 0,
                        height: 0,
                        properties: ["id": spawnID]
                    )
                }
            ]
        )
    }
}
