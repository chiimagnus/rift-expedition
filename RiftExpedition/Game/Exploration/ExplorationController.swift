import CoreGraphics
import Foundation
import RiftCore

struct PartyMemberPosition: Equatable {
    var actorID: String
    var displayName: String
    var classID: String?
    var position: CGPoint
    var target: CGPoint?
    var facing: ActorAnimationDirection = .right
    /// 领队点击目的地后经由 `NavigationService` 算出的剩余转折点（不包括 `target` 本身）。
    var waypoints: [CGPoint] = []
}

struct ExplorationController: Equatable {
    private(set) var members: [PartyMemberPosition] = []
    private(set) var leaderIndex = 0
    var followDistance: CGFloat = 42
    var moveSpeed: CGFloat = 220
    /// 每个角色移动时占用的“身位半径”：既用来算寻路时应该绕开障碍物多远，
    /// 也用来做每帧的兰底碰撞检查（防止贴着障碍物边缘走的时候整个人陷进去）。
    var agentRadius: CGFloat = 16

    /// 当前地图里“真正挡路”的障碍物（navObstacle 图层里 blocksMovement=true 的对象，
    /// 以及 GameSessionViewModel 额外加进来的 NPC 占位）。只有这里登记过的障碍物才会
    /// 影响寻路和碰撞——纯装饰性的障碍物（blocksMovement=false）完全不会拦人。
    private var obstacles: [NavigationObstacle] = []
    private var playableFrame: CGRect?

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

    /// 供 GameSessionViewModel 在切地图时调用，把当前地图“真正挡路”的障碍物同步进来。
    /// 之前这里完全是空的——移动只看直线距离，不管路上有没有障碍物，
    /// 所以障碍物纯粹是摆设，玩家可以直接穿过去。现在移动前会先绕开这些障碍物寻路，
    /// 每一步也会再做一次兰底碰撞检查，确保任何人都不能穿墙。
    mutating func configureNavigation(
        obstacles: [NavigationObstacle],
        playableFrame: CGRect
    ) {
        self.obstacles = obstacles.filter(\.blocksMovement)
        let standardizedFrame = playableFrame.standardized
        self.playableFrame = standardizedFrame.width > 0 && standardizedFrame.height > 0
            ? standardizedFrame
            : nil
    }

    @discardableResult
    mutating func setLeaderDestination(_ destination: CGPoint) -> Bool {
        guard members.indices.contains(leaderIndex), isInsidePlayableFrame(destination) else {
            return false
        }

        let start = members[leaderIndex].position
        if distance(from: start, to: destination) < 1 {
            members[leaderIndex].target = nil
            members[leaderIndex].waypoints = []
            refreshFollowerTargets(leaderDestination: destination)
            return true
        }

        var route = NavigationService(obstacles: obstacles, agentRadius: Float(agentRadius))
            .path(from: start, to: destination)
        if route.first == start {
            route.removeFirst()
        }
        guard !route.isEmpty, route.allSatisfy(isInsidePlayableFrame) else {
            return false
        }

        members[leaderIndex].waypoints = route
        members[leaderIndex].target = members[leaderIndex].waypoints.removeFirst()
        refreshFollowerTargets(leaderDestination: destination)
        return true
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

            let previousPosition = members[index].position
            let desired = movedPoint(from: previousPosition, toward: target, maxDistance: step)
            let resolved = resolvedPosition(from: previousPosition, desired: desired)
            members[index].position = resolved
            if let facing = facingDirection(from: previousPosition, to: resolved) {
                members[index].facing = facing
            }

            if distance(from: members[index].position, to: target) < 1 {
                members[index].position = target
                if !members[index].waypoints.isEmpty {
                    members[index].target = members[index].waypoints.removeFirst()
                } else {
                    members[index].target = nil
                }
            }
        }

        guard members.indices.contains(leaderIndex) else { return }
        refreshFollowerTargets(leaderDestination: members[leaderIndex].target ?? members[leaderIndex].position)

        // 队伍成员之间也要有基本的身位碰撞：解算完这一帧的移动后，把彼此重叠的成员推开，
        // 避免两个角色完全穿透、叠在同一个点上。
        separateOverlappingMembers()
    }

    private mutating func refreshFollowerTargets(leaderDestination: CGPoint) {
        guard members.indices.contains(leaderIndex) else { return }

        let leader = members[leaderIndex]
        let direction = normalizedVector(from: leader.position, to: leaderDestination) ?? CGPoint(x: 1, y: 0)
        var followerRank = 1

        for index in members.indices where index != leaderIndex {
            let desiredTarget = CGPoint(
                x: leaderDestination.x - direction.x * followDistance * CGFloat(followerRank),
                y: leaderDestination.y - direction.y * followDistance * CGFloat(followerRank)
            )
            members[index].target = clampedToPlayableFrame(desiredTarget)
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

    /// 障碍物阻挡的兰底实现：如果按直线走到的目标点会落进某个挡路障碍物（外扩一圈身位半径）
    /// 里，就试着“贴着墙滑一下”——先只挤 X，不行再只挤 Y，两个方向都挤不动就原地不动。
    /// 正常情况下 `setLeaderDestination` 已经用 `NavigationService` 绕开了障碍物，这里
    /// 只是给跟随的队友、以及寻路网格粒度没完全盖住的边缘情况兰底，确保任何人都不能穿墙。
    private func resolvedPosition(from start: CGPoint, desired: CGPoint) -> CGPoint {
        guard isBlocked(desired) else { return desired }

        let slideX = CGPoint(x: desired.x, y: start.y)
        if !isBlocked(slideX) { return slideX }

        let slideY = CGPoint(x: start.x, y: desired.y)
        if !isBlocked(slideY) { return slideY }

        return start
    }

    /// 队伍成员之间的身位碰撞：如果两个成员靠得比“两个身位半径”还近，就沿两人连线方向
    /// 把他们对半推开到刚好不重叠。完全重合时用一个默认方向掰开，避免除零。推开时同样
    /// 走 `isBlocked` 检查，绝不把人推进墙里（宁可暂时重叠，下一帧继续推）。
    private mutating func separateOverlappingMembers() {
        let minDistance = agentRadius * 2
        guard minDistance > 0 else { return }

        for i in members.indices {
            for j in members.indices where j > i {
                let a = members[i].position
                let b = members[j].position
                let gap = distance(from: a, to: b)
                guard gap < minDistance else { continue }

                let direction: CGPoint = gap > 0.001
                    ? CGPoint(x: (b.x - a.x) / gap, y: (b.y - a.y) / gap)
                    : CGPoint(x: 1, y: 0)
                let push = (minDistance - gap) / 2

                let pushedA = CGPoint(x: a.x - direction.x * push, y: a.y - direction.y * push)
                let pushedB = CGPoint(x: b.x + direction.x * push, y: b.y + direction.y * push)
                if !isBlocked(pushedA) { members[i].position = pushedA }
                if !isBlocked(pushedB) { members[j].position = pushedB }
            }
        }
    }

    private func facingDirection(from start: CGPoint, to end: CGPoint) -> ActorAnimationDirection? {
        let dx = end.x - start.x
        let dy = end.y - start.y
        guard abs(dx) > 0.01 || abs(dy) > 0.01 else { return nil }
        if abs(dx) > abs(dy) {
            return dx >= 0 ? .right : .left
        }
        return dy >= 0 ? .up : .down
    }

    private func isBlocked(_ point: CGPoint) -> Bool {
        guard isInsidePlayableFrame(point) else { return true }
        return obstacles.contains { $0.frame.insetBy(dx: -agentRadius, dy: -agentRadius).contains(point) }
    }

    private func isInsidePlayableFrame(_ point: CGPoint) -> Bool {
        guard let playableFrame else { return false }
        return playableFrame.insetBy(dx: agentRadius, dy: agentRadius).contains(point)
    }

    private func clampedToPlayableFrame(_ point: CGPoint) -> CGPoint {
        guard let playableFrame else { return point }
        let inset = playableFrame.insetBy(dx: agentRadius, dy: agentRadius)
        guard inset.width > 0, inset.height > 0 else { return point }
        return CGPoint(
            x: min(max(point.x, inset.minX), inset.maxX),
            y: min(max(point.y, inset.minY), inset.maxY)
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
