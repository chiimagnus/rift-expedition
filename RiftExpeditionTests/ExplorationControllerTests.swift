import CoreGraphics
import RiftCore
import XCTest
@testable import RiftExpedition

final class ExplorationControllerTests: XCTestCase {
    func testTabSwitchesLeader() {
        var controller = ExplorationController()
        controller.configureParty(actorFixtures, at: CGPoint(x: 100, y: 100))

        controller.switchToNextLeader()

        XCTAssertEqual(controller.leaderID, "player_2")
    }

    func testFollowerTargetUpdatesAfterLeaderPathChanges() throws {
        var controller = ExplorationController()
        controller.configureParty(actorFixtures, at: CGPoint(x: 100, y: 100))

        controller.setLeaderDestination(CGPoint(x: 300, y: 100))

        let follower = try XCTUnwrap(controller.members.first { $0.actorID == "player_2" })
        XCTAssertEqual(follower.target, CGPoint(x: 258, y: 100))
    }

    func testAdvanceMovesLeaderTowardTarget() throws {
        var controller = ExplorationController()
        controller.configureParty(actorFixtures, at: CGPoint(x: 100, y: 100))

        controller.setLeaderDestination(CGPoint(x: 300, y: 100))
        controller.advance(deltaTime: 0.5)

        let leader = try XCTUnwrap(controller.members.first { $0.actorID == "player_1" })
        XCTAssertGreaterThan(leader.position.x, 100)
        XCTAssertLessThan(leader.position.x, 300)
    }

    func testAdvanceUpdatesFacingOnMajorMovementAxis() throws {
        var controller = ExplorationController()
        controller.moveSpeed = 100
        controller.configureParty([actor(id: "player_1", displayName: "战士1")], at: CGPoint(x: 100, y: 100))

        controller.setLeaderDestination(CGPoint(x: 200, y: 100))
        controller.advance(deltaTime: 0.25)
        XCTAssertEqual(controller.members[0].facing, .right)

        controller.setLeaderDestination(CGPoint(x: 75, y: 100))
        controller.advance(deltaTime: 0.25)
        XCTAssertEqual(controller.members[0].facing, .left)

        controller.setLeaderDestination(CGPoint(x: controller.members[0].position.x, y: 200))
        controller.advance(deltaTime: 0.25)
        XCTAssertEqual(controller.members[0].facing, .up)

        controller.setLeaderDestination(CGPoint(x: controller.members[0].position.x, y: 50))
        controller.advance(deltaTime: 0.25)
        XCTAssertEqual(controller.members[0].facing, .down)
    }

    func testAdvanceKeepsFacingWhenMovementIsBlocked() throws {
        var controller = ExplorationController()
        controller.moveSpeed = 100
        controller.agentRadius = 0
        controller.configureParty([actor(id: "player_1", displayName: "战士1")], at: CGPoint(x: 100, y: 100))
        controller.setLeaderDestination(CGPoint(x: 140, y: 100))
        controller.setObstacles([
            NavigationObstacle(
                tiledID: 1,
                frame: CGRect(x: 120, y: 90, width: 30, height: 30),
                blocksMovement: true,
                blocksSight: false
            )
        ])

        controller.advance(deltaTime: 0.25)

        XCTAssertEqual(controller.members[0].position, CGPoint(x: 100, y: 100))
        XCTAssertEqual(controller.members[0].facing, .right)
    }

    func testConfigurePartyCarriesClassIDForRendering() throws {
        var controller = ExplorationController()
        controller.configureParty(
            [
                actor(id: "player_1", displayName: "战士1", classID: "warrior"),
                actor(id: "player_2", displayName: "法师2", classID: "mage")
            ],
            at: CGPoint(x: 100, y: 100)
        )

        let leader = try XCTUnwrap(controller.members.first { $0.actorID == "player_1" })
        let follower = try XCTUnwrap(controller.members.first { $0.actorID == "player_2" })
        XCTAssertEqual(leader.classID, "warrior")
        XCTAssertEqual(follower.classID, "mage")
    }

    private var actorFixtures: [Actor] {
        [
            actor(id: "player_1", displayName: "战士1"),
            actor(id: "player_2", displayName: "法师2")
        ]
    }

    private func actor(id: String, displayName: String, classID: String? = nil) -> Actor {
        Actor(
            id: id,
            displayName: displayName,
            kind: .player,
            faction: .player,
            level: 1,
            stats: Stats(
                maxHealth: 10,
                health: 10,
                attack: 3,
                defense: 2,
                evasion: 1,
                magic: 1,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            classID: classID,
            skillIDs: []
        )
    }
}
