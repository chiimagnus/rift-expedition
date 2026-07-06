import CoreGraphics
import Foundation
import RiftCore

struct PartyMemberPosition: Equatable {
    var actorID: String
    var displayName: String
    var classID: String?
    var position: CGPoint
    var target: CGPoint?
}

struct ExplorationController: Equatable {
    private(set) var members: [PartyMemberPosition] = []
    private(set) var leaderIndex = 0
    var followDistance: CGFloat = 42
    var moveSpeed: CGFloat = 220

    var leaderID: String? {
        guard members.indices.contains(leaderIndex) else { return nil }
        return members[leaderIndex].actorID
    }

    mutating func configureParty(_ actors: [Actor], at start: CGPoint) {
        members = actors.enumerated().map { index, actor in
            PartyMemberPosition(
                actorID: actor.id,
                displayName: actor.displayName,
                classID: actor.classID,
                position: CGPoint(x: start.x - CGFloat(index) * followDistance, y: start.y),
                target: nil
            )
        }
        leaderIndex = members.isEmpty ? 0 : min(leaderIndex, members.count - 1)
    }

    mutating func setLeaderDestination(_ destination: CGPoint) {
        guard members.indices.contains(leaderIndex) else { return }

        members[leaderIndex].target = destination
        refreshFollowerTargets(leaderDestination: destination)
    }

    mutating func switchToNextLeader() {
        guard !members.isEmpty else { return }

        leaderIndex = (leaderIndex + 1) % members.count
        if let destination = members[leaderIndex].target {
            refreshFollowerTargets(leaderDestination: destination)
        } else {
            refreshFollowerTargets(leaderDestination: members[leaderIndex].position)
        }
    }

    mutating func advance(deltaTime: TimeInterval) {
        guard deltaTime > 0 else { return }

        let step = moveSpeed * CGFloat(deltaTime)
        for index in members.indices {
            guard let target = members[index].target else { continue }
            members[index].position = movedPoint(from: members[index].position, toward: target, maxDistance: step)
            if distance(from: members[index].position, to: target) < 1 {
                members[index].position = target
                members[index].target = nil
            }
        }

        guard members.indices.contains(leaderIndex) else { return }
        refreshFollowerTargets(leaderDestination: members[leaderIndex].target ?? members[leaderIndex].position)
    }

    private mutating func refreshFollowerTargets(leaderDestination: CGPoint) {
        guard members.indices.contains(leaderIndex) else { return }

        let leader = members[leaderIndex]
        let direction = normalizedVector(from: leader.position, to: leaderDestination) ?? CGPoint(x: 1, y: 0)
        var followerRank = 1

        for index in members.indices where index != leaderIndex {
            members[index].target = CGPoint(
                x: leaderDestination.x - direction.x * followDistance * CGFloat(followerRank),
                y: leaderDestination.y - direction.y * followDistance * CGFloat(followerRank)
            )
            followerRank += 1
        }
    }

    private func movedPoint(from start: CGPoint, toward end: CGPoint, maxDistance: CGFloat) -> CGPoint {
        let total = distance(from: start, to: end)
        guard total > maxDistance, total > 0 else { return end }

        let ratio = maxDistance / total
        return CGPoint(
            x: start.x + (end.x - start.x) * ratio,
            y: start.y + (end.y - start.y) * ratio
        )
    }

    private func normalizedVector(from start: CGPoint, to end: CGPoint) -> CGPoint? {
        let total = distance(from: start, to: end)
        guard total > 0 else { return nil }

        return CGPoint(x: (end.x - start.x) / total, y: (end.y - start.y) / total)
    }

    private func distance(from start: CGPoint, to end: CGPoint) -> CGFloat {
        hypot(end.x - start.x, end.y - start.y)
    }
}
