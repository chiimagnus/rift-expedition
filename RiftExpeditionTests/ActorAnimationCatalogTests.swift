import CoreGraphics
import XCTest
@testable import RiftExpedition

final class ActorAnimationCatalogTests: XCTestCase {
    func testDecodesSpriteAndFrames() throws {
        let catalog = try ActorAnimationCatalog.decode(data: Self.catalogJSON)

        XCTAssertEqual(catalog.version, 1)
        XCTAssertEqual(catalog.sprite(for: "actor_warrior")?.sheet, "Assets/Characters/actor_warrior_anim.png")
        XCTAssertTrue(catalog.frames(for: "missing", action: .idle, direction: .down).isEmpty)
    }

    func testFrameRectsUseSpriteKitTextureCoordinates() throws {
        let catalog = try ActorAnimationCatalog.decode(data: Self.catalogJSON)
        let downFrames = catalog.frames(for: "actor_warrior", action: .idle, direction: .down)
        let leftFrames = catalog.frames(for: "actor_warrior", action: .walk, direction: .left)
        let rightFrames = catalog.frames(for: "actor_warrior", action: .attack, direction: .right)
        let upFrames = catalog.frames(for: "actor_warrior", action: .hurt, direction: .up)

        XCTAssertEqual(downFrames.count, 3)
        XCTAssertEqual(downFrames[0], CGRect(x: 0, y: 0.75, width: 1.0 / 12.0, height: 0.25))
        XCTAssertEqual(downFrames[2].origin.x, 2.0 / 12.0)
        XCTAssertEqual(leftFrames[0], CGRect(x: 3.0 / 12.0, y: 0.5, width: 1.0 / 12.0, height: 0.25))
        XCTAssertEqual(rightFrames[0], CGRect(x: 6.0 / 12.0, y: 0.25, width: 1.0 / 12.0, height: 0.25))
        XCTAssertEqual(upFrames[0], CGRect(x: 9.0 / 12.0, y: 0, width: 1.0 / 12.0, height: 0.25))
    }

    private static let catalogJSON = """
    {
      "version": 1,
      "frameSize": {
        "width": 96,
        "height": 96
      },
      "directions": ["down", "left", "right", "up"],
      "actions": {
        "idle": {
          "startColumn": 0,
          "frameCount": 3
        },
        "walk": {
          "startColumn": 3,
          "frameCount": 3
        },
        "attack": {
          "startColumn": 6,
          "frameCount": 3
        },
        "hurt": {
          "startColumn": 9,
          "frameCount": 3
        }
      },
      "sprites": [
        {
          "visualID": "actor_warrior",
          "sheet": "Assets/Characters/actor_warrior_anim.png"
        }
      ]
    }
    """.data(using: .utf8) ?? Data()
}
