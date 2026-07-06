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
            "<rect width=\"100%\" height=\"100%\" fill=\"#1f2a1f\"/>",
            "<text x=\"16\" y=\"28\" font-size=\"22\" fill=\"#f8fafc\">\(escape(map.areaID))</text>",
            "<text x=\"16\" y=\"52\" font-size=\"12\" fill=\"#cbd5e1\">底色=地形  棕色=障碍  青色=出生点  黄点=NPC  橙色=物品  红框=遭遇  蓝框=出口  紫框=触发器  半透明色块=地表</text>"
        ]
        for obstacle in map.objectGroups["navObstacle", default: []] {
            body.append("<rect x=\"\(obstacle.x)\" y=\"\(obstacle.y)\" width=\"\(obstacle.width)\" height=\"\(obstacle.height)\" fill=\"#5b3a29\" opacity=\"0.8\"/>")
        }
        for surface in map.objectGroups["surface", default: []] {
            body.append("<rect x=\"\(surface.x)\" y=\"\(surface.y)\" width=\"\(surface.width)\" height=\"\(surface.height)\" fill=\"\(surfaceColor(surface.properties["surfaceType"]))\" opacity=\"0.55\"/>")
        }
        for encounter in map.objectGroups["encounter", default: []] {
            body.append("<rect x=\"\(encounter.x)\" y=\"\(encounter.y)\" width=\"\(encounter.width)\" height=\"\(encounter.height)\" fill=\"none\" stroke=\"#ef4444\" stroke-width=\"3\"/>")
            body.append("<text x=\"\(encounter.x)\" y=\"\(encounter.y - 6)\" font-size=\"14\" fill=\"#fecaca\">\(escape(encounter.properties["encounterId"] ?? "encounter"))</text>")
        }
        for exit in map.objectGroups["exit", default: []] {
            body.append("<rect x=\"\(exit.x)\" y=\"\(exit.y)\" width=\"\(exit.width)\" height=\"\(exit.height)\" fill=\"none\" stroke=\"#60a5fa\" stroke-width=\"3\" stroke-dasharray=\"8 5\"/>")
            let targetAreaID = exit.properties["targetAreaId"] ?? "unknown"
            let targetSpawnID = exit.properties["targetSpawnId"] ?? "unknown"
            body.append("<text x=\"\(exit.x)\" y=\"\(exit.y - 6)\" font-size=\"14\" fill=\"#bfdbfe\">出口 \(escape(targetAreaID)).\(escape(targetSpawnID))</text>")
        }
        for trigger in map.objectGroups["trigger", default: []] {
            body.append("<rect x=\"\(trigger.x)\" y=\"\(trigger.y)\" width=\"\(trigger.width)\" height=\"\(trigger.height)\" fill=\"none\" stroke=\"#c084fc\" stroke-width=\"3\"/>")
            body.append("<text x=\"\(trigger.x)\" y=\"\(trigger.y + trigger.height + 16)\" font-size=\"13\" fill=\"#e9d5ff\">触发器 \(escape(trigger.properties["triggerId"] ?? "trigger"))</text>")
        }
        for npc in map.objectGroups["npc", default: []] {
            body.append("<circle cx=\"\(npc.x)\" cy=\"\(npc.y)\" r=\"8\" fill=\"#facc15\"/>")
            body.append("<text x=\"\(npc.x + 10)\" y=\"\(npc.y + 4)\" font-size=\"13\" fill=\"#fef3c7\">\(escape(npc.properties["actorId"] ?? "npc"))</text>")
        }
        for item in map.objectGroups["item", default: []] {
            body.append("<rect x=\"\(item.x - 6)\" y=\"\(item.y - 6)\" width=\"12\" height=\"12\" fill=\"#f59e0b\"/>")
            body.append("<text x=\"\(item.x + 10)\" y=\"\(item.y + 4)\" font-size=\"12\" fill=\"#fed7aa\">\(escape(item.properties["itemId"] ?? "item"))</text>")
        }
        for spawn in map.objectGroups["spawn", default: []] {
            body.append("<circle cx=\"\(spawn.x)\" cy=\"\(spawn.y)\" r=\"6\" fill=\"#6ee7b7\"/>")
            body.append("<text x=\"\(spawn.x + 10)\" y=\"\(spawn.y + 4)\" font-size=\"12\" fill=\"#ccfbf1\">\(escape(spawn.properties["id"] ?? "spawn"))</text>")
        }
        body.append("</svg>")
        return body.joined(separator: "\n") + "\n"
    }

    private static func surfaceColor(_ type: String?) -> String {
        switch type {
        case "water":
            "#38bdf8"
        case "oil":
            "#18181b"
        case "poison":
            "#84cc16"
        case "fire":
            "#f97316"
        default:
            "#a3a3a3"
        }
    }

    private static func escape(_ value: String) -> String {
        value
            .replacing("&", with: "&amp;")
            .replacing("<", with: "&lt;")
            .replacing(">", with: "&gt;")
            .replacing("\"", with: "&quot;")
    }
}
