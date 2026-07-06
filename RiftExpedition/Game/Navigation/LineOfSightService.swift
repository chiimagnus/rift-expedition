import CoreGraphics

struct LineOfSightService {
    private let blockingRects: [CGRect]

    init(obstacles: [NavigationObstacle]) {
        blockingRects = obstacles
            .filter(\.blocksSight)
            .map(\.frame)
    }

    func hasLineOfSight(from start: CGPoint, to end: CGPoint) -> Bool {
        !blockingRects.contains { rect in
            rect.intersectsSegment(from: start, to: end)
        }
    }
}

extension CGRect {
    func intersectsSegment(from start: CGPoint, to end: CGPoint) -> Bool {
        if contains(start) || contains(end) {
            return true
        }

        let topLeft = CGPoint(x: minX, y: minY)
        let topRight = CGPoint(x: maxX, y: minY)
        let bottomRight = CGPoint(x: maxX, y: maxY)
        let bottomLeft = CGPoint(x: minX, y: maxY)

        return segmentsIntersect(start, end, topLeft, topRight)
            || segmentsIntersect(start, end, topRight, bottomRight)
            || segmentsIntersect(start, end, bottomRight, bottomLeft)
            || segmentsIntersect(start, end, bottomLeft, topLeft)
    }
}

private func segmentsIntersect(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> Bool {
    let first = orientation(a, b, c)
    let second = orientation(a, b, d)
    let third = orientation(c, d, a)
    let fourth = orientation(c, d, b)

    if first == 0, point(c, liesOnSegmentFrom: a, to: b) { return true }
    if second == 0, point(d, liesOnSegmentFrom: a, to: b) { return true }
    if third == 0, point(a, liesOnSegmentFrom: c, to: d) { return true }
    if fourth == 0, point(b, liesOnSegmentFrom: c, to: d) { return true }

    return (first > 0) != (second > 0) && (third > 0) != (fourth > 0)
}

private func orientation(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
    let value = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    return abs(value) < 0.0001 ? 0 : value
}

private func point(_ point: CGPoint, liesOnSegmentFrom start: CGPoint, to end: CGPoint) -> Bool {
    point.x >= min(start.x, end.x) - 0.0001
        && point.x <= max(start.x, end.x) + 0.0001
        && point.y >= min(start.y, end.y) - 0.0001
        && point.y <= max(start.y, end.y) + 0.0001
}
