import CoreGraphics
import GameplayKit
import simd

struct NavigationService {
    private let obstacles: [NavigationObstacle]
    private let agentRadius: Float

    init(obstacles: [NavigationObstacle], agentRadius: Float = 10) {
        self.obstacles = obstacles.filter(\.blocksMovement)
        self.agentRadius = agentRadius
    }

    func path(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        guard start != end else { return [start] }

        let sight = LineOfSightService(obstacles: obstacles.map {
            NavigationObstacle(
                tiledID: $0.tiledID,
                frame: $0.frame,
                blocksMovement: $0.blocksMovement,
                blocksSight: true
            )
        })
        if sight.hasLineOfSight(from: start, to: end) {
            return [start, end]
        }

        let polygonObstacles = obstacles.map { obstacle in
            polygonObstacle(for: obstacle.frame)
        }
        let graph = GKObstacleGraph<GKGraphNode2D>(obstacles: polygonObstacles, bufferRadius: agentRadius)
        let startNode = GKGraphNode2D(point: vector_float2(Float(start.x), Float(start.y)))
        let endNode = GKGraphNode2D(point: vector_float2(Float(end.x), Float(end.y)))

        graph.connectUsingObstacles(node: startNode)
        graph.connectUsingObstacles(node: endNode)

        let nodes = graph.findPath(from: startNode, to: endNode) as? [GKGraphNode2D] ?? []
        return nodes.map { node in
            CGPoint(x: CGFloat(node.position.x), y: CGFloat(node.position.y))
        }
    }

    private func polygonObstacle(for rect: CGRect) -> GKPolygonObstacle {
        let points = [
            vector_float2(Float(rect.minX), Float(rect.minY)),
            vector_float2(Float(rect.maxX), Float(rect.minY)),
            vector_float2(Float(rect.maxX), Float(rect.maxY)),
            vector_float2(Float(rect.minX), Float(rect.maxY))
        ]
        return GKPolygonObstacle(points: points)
    }
}
