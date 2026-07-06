import CoreGraphics
import Foundation
import RiftCore

struct PartyMemberPosition: Equatable {
    var actorID: String
    var displayName: String
    var classID: String?
    var position: CGPoint
    var target: CGPoint?
    /// 上一次有效水平移动后面朝的方向，GameScene 用它来左右镜像翻转立绘，
    /// 这样角色向左走时不会看起来像是倒退着走路。
    var facingRight: Bool = true
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
    mutating func setObstacles(_ obstacles: [NavigationObstacle]) {
        self.obstacles = obstacles.filter(\.blocksMovement)
    }

    mutating func setLeaderDestination(_ destination: CGPoint) {
        guard members.indices.contains(leaderIndex) else { return }

        let start = members[leaderIndex].position
        var route = NavigationService(obstacles: obstacles, agentRadius: Float(agentRadius))
            .path(from: start, to: destination)
        if route.first == start {
            route.removeFirst()
        }
        if route.isEmpty {
            route = [destination]
        }

        members[leaderIndex].waypoints = route
        members[leaderIndex].target = members[leaderIndex].waypoints.isEmpty
            ? nil
            : members[leaderIndex].waypoints.removeFirst()
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

            let previousPosition = members[index].position
            let desired = movedPoint(from: previousPosition, toward: target, maxDistance: step)
            let resolved = resolvedPosition(from: previousPosition, desired: desired)
            members[index].position = resolved
            if abs(resolved.x - previousPosition.x) > 0.01 {
                members[index].facingRight = resolved.x >= previousPosition.x
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

    private func isBlocked(_ point: CGPoint) -> Bool {
        obstacles.contains { $0.frame.insetBy(dx: -agentRadius, dy: -agentRadius).contains(point) }
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
