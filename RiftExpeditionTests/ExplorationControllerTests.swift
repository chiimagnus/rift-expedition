import CoreGraphics
import RiftCore
import XCTest
@testable import RiftExpedition

final class ExplorationControllerTests: XCTestCase {
    func testTabSwitchesLeader() {
        var controller = controllerFixture()
        controller.configureParty(actorFixtures, at: CGPoint(x: 100, y: 100))

        controller.switchToNextLeader()

        XCTAssertEqual(controller.leaderID, "player_2")
    }

    func testFollowerTargetUpdatesAfterLeaderPathChanges() throws {
        var controller = controllerFixture()
        controller.configureParty(actorFixtures, at: CGPoint(x: 100, y: 100))

        controller.setLeaderDestination(CGPoint(x: 300, y: 100))

        let follower = try XCTUnwrap(controller.members.first { $0.actorID == "player_2" })
        XCTAssertEqual(follower.target, CGPoint(x: 258, y: 100))
    }

    func testAdvanceMovesLeaderTowardTarget() throws {
        var controller = controllerFixture()
        controller.configureParty(actorFixtures, at: CGPoint(x: 100, y: 100))

        controller.setLeaderDestination(CGPoint(x: 300, y: 100))
        controller.advance(deltaTime: 0.5)

        let leader = try XCTUnwrap(controller.members.first { $0.actorID == "player_1" })
        XCTAssertGreaterThan(leader.position.x, 100)
        XCTAssertLessThan(leader.position.x, 300)
    }

    func testAdvanceUpdatesFacingOnMajorMovementAxis() throws {
        var controller = controllerFixture()
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
        var controller = controllerFixture()
        controller.moveSpeed = 100
        controller.agentRadius = 0
        controller.configureParty([actor(id: "player_1", displayName: "战士1")], at: CGPoint(x: 100, y: 100))
        controller.setLeaderDestination(CGPoint(x: 140, y: 100))
        controller.configureNavigation(
            obstacles: [
                NavigationObstacle(
                    tiledID: 1,
                    frame: CGRect(x: 120, y: 90, width: 30, height: 30),
                    blocksMovement: true,
                    blocksSight: false
                )
            ],
            playableFrame: testPlayableFrame
        )

        controller.advance(deltaTime: 0.25)

        XCTAssertEqual(controller.members[0].position, CGPoint(x: 100, y: 100))
        XCTAssertEqual(controller.members[0].facing, .right)
    }

    func testDestinationOutsidePlayableFrameIsRejectedWithoutMovingParty() throws {
        var controller = controllerFixture()
        controller.configureParty(actorFixtures, at: CGPoint(x: 100, y: 100))

        XCTAssertFalse(controller.setLeaderDestination(CGPoint(x: -10, y: 100)))
        controller.advance(deltaTime: 1)

        let leader = try XCTUnwrap(controller.members.first { $0.actorID == "player_1" })
        XCTAssertEqual(leader.position, CGPoint(x: 100, y: 100))
        XCTAssertNil(leader.target)
    }

    func testRouteThatEscapesPlayableFrameIsRejected() throws {
        var controller = ExplorationController()
        controller.configureNavigation(
            obstacles: [
                NavigationObstacle(
                    tiledID: 1,
                    frame: CGRect(x: 180, y: 0, width: 40, height: 300),
                    blocksMovement: true,
                    blocksSight: true
                )
            ],
            playableFrame: testPlayableFrame
        )
        controller.configureParty(
            [actor(id: "player_1", displayName: "战士1")],
            at: CGPoint(x: 100, y: 150)
        )

        XCTAssertFalse(controller.setLeaderDestination(CGPoint(x: 300, y: 150)))
        let leader = try XCTUnwrap(controller.members.first)
        XCTAssertNil(leader.target)
        XCTAssertTrue(leader.waypoints.isEmpty)
    }

    func testConfigurePartyCarriesClassIDForRendering() throws {
        var controller = controllerFixture()
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


    private var testPlayableFrame: CGRect {
        CGRect(x: 0, y: 0, width: 400, height: 300)
    }

    private func controllerFixture() -> ExplorationController {
        var controller = ExplorationController()
        controller.configureNavigation(obstacles: [], playableFrame: testPlayableFrame)
        return controller
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
