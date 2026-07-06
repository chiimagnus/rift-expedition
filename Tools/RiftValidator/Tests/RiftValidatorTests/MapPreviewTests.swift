import Foundation
import XCTest
@testable import RiftValidator

final class MapPreviewTests: XCTestCase {
    func testPreviewIncludesExitTriggerAndLegend() throws {
        let output = URL.temporaryDirectory
            .appending(path: "RiftValidatorPreviewTests")
            .appending(path: UUID().uuidString)
        let result = MapValidationResult(
            map: TiledMap(
                areaID: "preview_test",
                width: 320,
                height: 240,
                objectGroups: [
                    "spawn": [object(id: 1, x: 32, y: 32, properties: ["id": "start"])],
                    "exit": [object(id: 2, x: 280, y: 80, width: 32, height: 64, properties: ["targetAreaId": "next", "targetSpawnId": "entry"])],
                    "trigger": [object(id: 3, x: 120, y: 96, width: 40, height: 40, properties: ["triggerId": "ending", "action": "chapterComplete"])],
                    "item": [object(id: 4, x: 80, y: 160, properties: ["itemId": "minor_healing_draught"])]
                ]
            ),
            issues: []
        )

        try MapPreview.writePreview(for: result, to: output)
        let svg = try String(contentsOf: output.appending(path: "preview_test.svg"), encoding: .utf8)

        XCTAssertTrue(svg.contains("底色=地形"))
        XCTAssertTrue(svg.contains("出口 next.entry"))
        XCTAssertTrue(svg.contains("触发器 ending"))
        XCTAssertTrue(svg.contains("minor_healing_draught"))
    }

    private func object(
        id: Int,
        x: Double,
        y: Double,
        width: Double = 0,
        height: Double = 0,
        properties: [String: String]
    ) -> TiledObject {
        TiledObject(
            tiledID: id,
            name: nil,
            type: nil,
            x: x,
            y: y,
            width: width,
            height: height,
            properties: properties
        )
    }
}
