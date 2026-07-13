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

    func testMissingNpcSizeFailsWithReadableError() throws {
        let result = try MapValidator.validate(url: fixture("invalid-map-missing-npc-size"))

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.reportMarkdown().contains("npc object 2 missing hitbox size"))
    }


    func testKeyGameplayObjectInsideMovementObstacleFails() throws {
        let source = try String(contentsOf: fixture("valid-map"), encoding: .utf8)
        let overlapping = source.replacingOccurrences(
            of: #"<object id="6" x="96" y="96" width="64" height="64">"#,
            with: #"<object id="6" x="60" y="28" width="48" height="48">"#
        )
        let directory = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "overlapping-object.tmx")
        try overlapping.write(to: url, atomically: true, encoding: .utf8)

        let result = try MapValidator.validate(url: url)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.reportMarkdown().contains("npc object 2 center is inside movement obstacle"))
    }

    func testGameplayObjectsMustStayInsideMapBounds() throws {
        let source = try String(contentsOf: fixture("valid-map"), encoding: .utf8)
        let invalid = source.replacingOccurrences(
            of: #"<object id="8" x="224" y="96">"#,
            with: #"<object id="8" x="336" y="96">"#
        )
        let directory = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "out-of-bounds-object.tmx")
        try invalid.write(to: url, atomically: true, encoding: .utf8)

        let result = try MapValidator.validate(url: url)

        XCTAssertTrue(result.issues.contains {
            $0.message == "item object 8 is outside map bounds"
        })
    }

    func testSpawnMustNotOverlapExit() throws {
        let source = try String(contentsOf: fixture("valid-map"), encoding: .utf8)
        let invalid = source.replacingOccurrences(
            of: #"<object id="5" x="288" y="160">"#,
            with: #"<object id="5" x="16" y="16" width="64" height="64">"#
        )
        let directory = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "spawn-exit-overlap.tmx")
        try invalid.write(to: url, atomically: true, encoding: .utf8)

        let result = try MapValidator.validate(url: url)

        XCTAssertTrue(result.issues.contains {
            $0.message == "spawn object 1 overlaps exit object 5"
        })
    }

    func testEverySpawnMustReachTheMapExit() throws {
        var source = try String(contentsOf: fixture("valid-map"), encoding: .utf8)
        source = source.replacingOccurrences(
            of: "    </object>\n  </objectgroup>\n  <objectgroup name=\"npc\">",
            with: "    </object>\n    <object id=\"9\" x=\"256\" y=\"32\">\n      <properties><property name=\"id\" value=\"isolated\"/></properties>\n    </object>\n  </objectgroup>\n  <objectgroup name=\"npc\">"
        )
        source = source.replacingOccurrences(
            of: #"<object id="5" x="288" y="160">"#,
            with: #"<object id="5" x="64" y="160">"#
        )
        source = source.replacingOccurrences(
            of: #"<object id="6" x="96" y="96" width="64" height="64">"#,
            with: #"<object id="6" x="144" y="0" width="32" height="320">"#
        )
        let directory = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "isolated-spawn.tmx")
        try source.write(to: url, atomically: true, encoding: .utf8)

        let result = try MapValidator.validate(url: url)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(
            result.reportMarkdown().contains("Unreachable exit valid-map from spawn isolated"),
            result.reportMarkdown()
        )
    }

    func testCrossAreaExitCanTargetSpawnInAnotherMap() throws {
        let results = try MapValidator.validate(urls: [
            fixture("cross-a"),
            fixture("cross-b")
        ])

        XCTAssertTrue(results.allSatisfy(\.isValid), results.map { $0.reportMarkdown() }.joined(separator: "\n"))
    }



    func testDuplicateMapAreaIDsAreReportedWithoutCrashing() throws {
        let root = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let firstDirectory = root.appending(path: "a")
        let secondDirectory = root.appending(path: "b")
        try FileManager.default.createDirectory(at: firstDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondDirectory, withIntermediateDirectories: true)
        let first = firstDirectory.appending(path: "duplicate.tmx")
        let second = secondDirectory.appending(path: "duplicate.tmx")
        try FileManager.default.copyItem(at: fixture("valid-map"), to: first)
        try FileManager.default.copyItem(at: fixture("valid-map"), to: second)

        let results = try MapValidator.validate(urls: [first, second])

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { result in
            result.issues.contains { $0.message == "Duplicate map area id: duplicate" }
        })
    }

    func testChapterIsNeverInferredFromOutputPath() throws {
        let arguments = try parseArguments([
            "RiftValidator",
            "/tmp/resources",
            "--write-report",
            "/tmp/chapter1-validation.md"
        ])

        XCTAssertNil(arguments.chapterID)
    }

    func testUnknownChapterFailsInsteadOfFallingBackToAllMaps() throws {
        let root = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(
            at: root.appending(path: "Data/worlds"),
            withIntermediateDirectories: true
        )

        XCTAssertThrowsError(
            try validationMapURLs(resourcesRoot: root, chapterID: "chapter_typo", areaID: nil)
        ) { error in
            XCTAssertTrue(String(describing: error).contains("Unknown chapter chapter_typo"))
        }
    }

    func testAreaRequiresExplicitChapter() {
        XCTAssertThrowsError(try parseArguments([
            "RiftValidator",
            "/tmp/resources",
            "--area",
            "village_square"
        ])) { error in
            XCTAssertTrue(String(describing: error).contains("--area requires an explicit --chapter"))
        }
    }

    func testUnknownAreaFailsInsteadOfReturningAnEmptySuccessScope() throws {
        let root = try makeChapterFixture(areaIDs: ["village_square"])
        defer { try? FileManager.default.removeItem(at: root) }

        XCTAssertThrowsError(
            try validationMapURLs(resourcesRoot: root, chapterID: "chapter1", areaID: "village_typo")
        ) { error in
            XCTAssertTrue(String(describing: error).contains("Unknown area village_typo in chapter chapter1"))
        }
    }

    func testChapterScopeResolvesOnlyWorldGraphMapsBeforeParsing() throws {
        let root = try makeChapterFixture(areaIDs: ["village_square"])
        defer { try? FileManager.default.removeItem(at: root) }
        let otherChapterRoot = root.appending(path: "Maps/chapter2")
        try FileManager.default.createDirectory(at: otherChapterRoot, withIntermediateDirectories: true)
        try "<not valid tmx>".write(
            to: otherChapterRoot.appending(path: "broken.tmx"),
            atomically: true,
            encoding: .utf8
        )

        let urls = try validationMapURLs(resourcesRoot: root, chapterID: "chapter1", areaID: nil)

        XCTAssertEqual(urls.map(\.lastPathComponent), ["village_square.tmx"])
        XCTAssertEqual(try MapValidator.validate(urls: urls).count, 1)
    }

    func testChapterScopeFailsWhenWorldGraphMapIsMissing() throws {
        let root = try makeChapterFixture(areaIDs: ["village_square"])
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.removeItem(at: root.appending(path: "Maps/chapter1/village_square.tmx"))

        XCTAssertThrowsError(
            try validationMapURLs(resourcesRoot: root, chapterID: "chapter1", areaID: nil)
        ) { error in
            XCTAssertTrue(String(describing: error).contains("references missing map"))
        }
    }

    func testWorldGraphDuplicateIDsAreReportedWithoutCrashing() {
        let duplicateMapA = map("duplicate", spawns: ["start"])
        let duplicateMapB = map("duplicate", spawns: ["entry"])
        let graph = ChapterWorldGraph(
            id: "test",
            title: "Duplicate world",
            startAreaId: "duplicate",
            startSpawnId: "start",
            areas: [
                ChapterWorldArea(
                    id: "duplicate",
                    displayName: "A",
                    biome: "test",
                    mapPath: "Maps/a.tmx",
                    exits: []
                ),
                ChapterWorldArea(
                    id: "duplicate",
                    displayName: "B",
                    biome: "test",
                    mapPath: "Maps/b.tmx",
                    exits: []
                )
            ]
        )

        let result = WorldGraphValidator.validate(graph, maps: [duplicateMapA, duplicateMapB])

        XCTAssertTrue(result.issues.contains { $0.message == "Duplicate TMX map area id: duplicate" })
        XCTAssertTrue(result.issues.contains { $0.message == "Duplicate world area id: duplicate" })
    }

    func testWorldGraphRejectsBlankMetadataAndDuplicateExitIDs() {
        let graph = ChapterWorldGraph(
            id: " ",
            title: " ",
            startAreaId: " ",
            startSpawnId: " ",
            areas: [
                ChapterWorldArea(
                    id: "area",
                    displayName: " ",
                    biome: " ",
                    mapPath: " ",
                    exits: [
                        ChapterWorldExit(id: "same", targetAreaId: " ", targetSpawnId: " "),
                        ChapterWorldExit(id: "same", targetAreaId: "missing", targetSpawnId: "entry")
                    ]
                )
            ]
        )

        let result = WorldGraphValidator.validate(graph, maps: [map("area", spawns: ["entry"])])
        let messages = Set(result.issues.map(\.message))

        XCTAssertTrue(messages.contains("World id must not be blank"))
        XCTAssertTrue(messages.contains("World title must not be blank"))
        XCTAssertTrue(messages.contains("World startAreaId must not be blank"))
        XCTAssertTrue(messages.contains("World startSpawnId must not be blank"))
        XCTAssertTrue(messages.contains("World area area displayName must not be blank"))
        XCTAssertTrue(messages.contains("World area area biome must not be blank"))
        XCTAssertTrue(messages.contains("World area area mapPath must not be blank"))
        XCTAssertTrue(messages.contains("Duplicate world exit id in area: same"))
        XCTAssertTrue(messages.contains("World exit area.same targetAreaId must not be blank"))
        XCTAssertTrue(messages.contains("World exit area.same targetSpawnId must not be blank"))
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

    func testWorldGraphValidationCanScopeToOneChapter() throws {
        let root = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let worldsRoot = root.appending(path: "Data/worlds")
        try FileManager.default.createDirectory(at: worldsRoot, withIntermediateDirectories: true)

        let chapter1: [String: Any] = [
            "id": "chapter1",
            "title": "Chapter 1",
            "startAreaId": "a",
            "startSpawnId": "start",
            "areas": [[
                "id": "a",
                "displayName": "A",
                "biome": "test",
                "mapPath": "Maps/a.tmx",
                "exits": []
            ]]
        ]
        let chapter2: [String: Any] = [
            "id": "chapter2",
            "title": "Chapter 2",
            "startAreaId": "missing",
            "startSpawnId": "missing",
            "areas": []
        ]
        try JSONSerialization.data(withJSONObject: chapter1).write(to: worldsRoot.appending(path: "chapter1.json"))
        try JSONSerialization.data(withJSONObject: chapter2).write(to: worldsRoot.appending(path: "chapter2.json"))

        let results = try WorldGraphValidator.validateIfPresent(
            resourcesRoot: root,
            maps: [map("a", spawns: ["start"])],
            worldID: "chapter1"
        )

        XCTAssertEqual(results.map(\.worldID), ["chapter1"])
        XCTAssertTrue(results.allSatisfy(\.isValid))
    }


    func testScopedWorldGraphValidationRejectsMismatchedInternalID() throws {
        let root = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let worldsRoot = root.appending(path: "Data/worlds")
        try FileManager.default.createDirectory(at: worldsRoot, withIntermediateDirectories: true)
        let mismatched: [String: Any] = [
            "id": "chapter2",
            "title": "Wrong Chapter",
            "startAreaId": "a",
            "startSpawnId": "start",
            "areas": []
        ]
        try JSONSerialization.data(withJSONObject: mismatched).write(to: worldsRoot.appending(path: "chapter1.json"))

        let results = try WorldGraphValidator.validateIfPresent(
            resourcesRoot: root,
            maps: [],
            worldID: "chapter1"
        )

        XCTAssertEqual(results.first?.worldID, "chapter1")
        XCTAssertTrue(results.first?.issues.contains { $0.message.contains("expected chapter1, found chapter2") } == true)
    }

    func testScopedWorldGraphValidationIgnoresMalformedSiblingChapter() throws {
        let root = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let worldsRoot = root.appending(path: "Data/worlds")
        try FileManager.default.createDirectory(at: worldsRoot, withIntermediateDirectories: true)

        let chapter1: [String: Any] = [
            "id": "chapter1",
            "title": "Chapter 1",
            "startAreaId": "a",
            "startSpawnId": "start",
            "areas": [[
                "id": "a",
                "displayName": "A",
                "biome": "test",
                "mapPath": "Maps/a.tmx",
                "exits": []
            ]]
        ]
        try JSONSerialization.data(withJSONObject: chapter1).write(to: worldsRoot.appending(path: "chapter1.json"))
        try Data("{ not valid json".utf8).write(to: worldsRoot.appending(path: "chapter2.json"))

        let results = try WorldGraphValidator.validateIfPresent(
            resourcesRoot: root,
            maps: [map("a", spawns: ["start"])],
            worldID: "chapter1"
        )

        XCTAssertEqual(results.map(\.worldID), ["chapter1"])
        XCTAssertTrue(results.allSatisfy(\.isValid))
    }

    func testMalformedNPCDataFailsReferenceValidation() throws {
        let root = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let dataRoot = root.appending(path: "Data")
        try FileManager.default.createDirectory(at: dataRoot, withIntermediateDirectories: true)
        try "[]".write(to: dataRoot.appending(path: "encounters.json"), atomically: true, encoding: .utf8)
        try "[]".write(to: dataRoot.appending(path: "items.json"), atomically: true, encoding: .utf8)
        try "[]".write(to: dataRoot.appending(path: "dialogs.json"), atomically: true, encoding: .utf8)
        try "{ malformed".write(to: dataRoot.appending(path: "npcs.json"), atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try MapReferenceValidator.validateIfPresent(resourcesRoot: root, maps: []))
    }

    func testMapReferenceValidationRejectsBlankAndDuplicateNPCMetadata() throws {
        let root = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let dataRoot = root.appending(path: "Data")
        try FileManager.default.createDirectory(at: dataRoot, withIntermediateDirectories: true)
        try "[]".write(to: dataRoot.appending(path: "encounters.json"), atomically: true, encoding: .utf8)
        try "[]".write(to: dataRoot.appending(path: "items.json"), atomically: true, encoding: .utf8)
        try "[]".write(to: dataRoot.appending(path: "dialogs.json"), atomically: true, encoding: .utf8)
        try #"""
        [
          {"id":" " ,"displayName":"Blank id"},
          {"id":"mayor","displayName":" "},
          {"id":"guard","displayName":"Guard"},
          {"id":"guard","displayName":"Guard Copy"}
        ]
        """#.write(to: dataRoot.appending(path: "npcs.json"), atomically: true, encoding: .utf8)

        let result = try XCTUnwrap(try MapReferenceValidator.validateIfPresent(resourcesRoot: root, maps: []))
        let messages = Set(result.issues.map(\.message))

        XCTAssertTrue(messages.contains("NPC id must not be blank"))
        XCTAssertTrue(messages.contains("NPC mayor displayName must not be blank"))
        XCTAssertTrue(messages.contains("Duplicate NPC id: guard"))
    }

    func testMapReferenceValidationRejectsUnknownAndEmptyTriggerActions() throws {
        let root = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let dataRoot = root.appending(path: "Data")
        try FileManager.default.createDirectory(at: dataRoot, withIntermediateDirectories: true)
        try "[]".write(to: dataRoot.appending(path: "encounters.json"), atomically: true, encoding: .utf8)
        try "[]".write(to: dataRoot.appending(path: "items.json"), atomically: true, encoding: .utf8)
        try #"[{"id":"known_dialog"}]"#.write(
            to: dataRoot.appending(path: "dialogs.json"),
            atomically: true,
            encoding: .utf8
        )
        let map = TiledMap(
            areaID: "test",
            width: 320,
            height: 320,
            objectGroups: [
                "trigger": [
                    TiledObject(
                        tiledID: 1, name: nil, type: nil, x: 32, y: 32, width: 32, height: 32,
                        properties: ["triggerId": "typo", "action": "dialog:known_dialog"]
                    ),
                    TiledObject(
                        tiledID: 2, name: nil, type: nil, x: 64, y: 32, width: 32, height: 32,
                        properties: ["triggerId": "empty", "action": "dialogue:   "]
                    ),
                    TiledObject(
                        tiledID: 3, name: nil, type: nil, x: 96, y: 32, width: 32, height: 32,
                        properties: ["triggerId": "ending", "action": "chapterComplete"]
                    ),
                    TiledObject(
                        tiledID: 4, name: nil, type: nil, x: 128, y: 32, width: 32, height: 32,
                        properties: ["triggerId": "dialogue", "action": "dialogue:known_dialog"]
                    )
                ]
            ]
        )

        let result = try XCTUnwrap(try MapReferenceValidator.validateIfPresent(resourcesRoot: root, maps: [map]))

        XCTAssertEqual(result.issues.count, 2)
        XCTAssertTrue(result.issues.contains { $0.message.contains("unsupported action: dialog:known_dialog") })
        XCTAssertTrue(result.issues.contains { $0.message.contains("empty dialogue action") })
    }

    func testMapReferenceValidationCatchesMissingItem() throws {
        let root = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        let dataRoot = root.appending(path: "Data")
        try FileManager.default.createDirectory(at: dataRoot, withIntermediateDirectories: true)
        try "[]".write(to: dataRoot.appending(path: "encounters.json"), atomically: true, encoding: .utf8)
        try "[]".write(to: dataRoot.appending(path: "items.json"), atomically: true, encoding: .utf8)
        try "[]".write(to: dataRoot.appending(path: "dialogs.json"), atomically: true, encoding: .utf8)
        let map = TiledMap(
            areaID: "test",
            width: 320,
            height: 320,
            objectGroups: [
                "item": [
                    TiledObject(
                        tiledID: 1,
                        name: nil,
                        type: nil,
                        x: 32,
                        y: 32,
                        width: 0,
                        height: 0,
                        properties: ["itemId": "missing_item"]
                    )
                ]
            ]
        )

        let result = try XCTUnwrap(try MapReferenceValidator.validateIfPresent(resourcesRoot: root, maps: [map]))

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.reportMarkdown().contains("references missing item: missing_item"))
    }

    private func makeChapterFixture(areaIDs: [String]) throws -> URL {
        let root = URL.temporaryDirectory
            .appending(path: "RiftValidatorTests")
            .appending(path: UUID().uuidString)
        let mapsRoot = root.appending(path: "Maps/chapter1")
        let worldsRoot = root.appending(path: "Data/worlds")
        try FileManager.default.createDirectory(at: mapsRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: worldsRoot, withIntermediateDirectories: true)

        for areaID in areaIDs {
            try FileManager.default.copyItem(
                at: try fixture("valid-map"),
                to: mapsRoot.appending(path: "\(areaID).tmx")
            )
        }

        let areas: [[String: Any]] = areaIDs.map { areaID in
            [
                "id": areaID,
                "displayName": areaID,
                "biome": "test",
                "mapPath": "Maps/chapter1/\(areaID).tmx",
                "exits": []
            ]
        }
        let graph: [String: Any] = [
            "id": "chapter1",
            "title": "Chapter 1",
            "startAreaId": areaIDs.first ?? "missing",
            "startSpawnId": "start",
            "areas": areas
        ]
        try JSONSerialization.data(withJSONObject: graph).write(
            to: worldsRoot.appending(path: "chapter1.json")
        )
        return root
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
