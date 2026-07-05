import Foundation

public enum MapPreview {
    public static func writePreview(for result: MapValidationResult, to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "\(result.map.areaID).svg")
        try svg(for: result.map).write(to: url, atomically: true, encoding: .utf8)
    }

    private static func svg(for map: TiledMap) -> String {
        var body: [String] = [
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(map.width)\" height=\"\(map.height)\" viewBox=\"0 0 \(map.width) \(map.height)\">",
            "<rect width=\"100%\" height=\"100%\" fill=\"#1f2a1f\"/>"
        ]
        for obstacle in map.objectGroups["navObstacle", default: []] {
            body.append("<rect x=\"\(obstacle.x)\" y=\"\(obstacle.y)\" width=\"\(obstacle.width)\" height=\"\(obstacle.height)\" fill=\"#5b3a29\" opacity=\"0.8\"/>")
        }
        for spawn in map.objectGroups["spawn", default: []] {
            body.append("<circle cx=\"\(spawn.x)\" cy=\"\(spawn.y)\" r=\"6\" fill=\"#6ee7b7\"/>")
        }
        body.append("</svg>")
        return body.joined(separator: "\n") + "\n"
    }
}
