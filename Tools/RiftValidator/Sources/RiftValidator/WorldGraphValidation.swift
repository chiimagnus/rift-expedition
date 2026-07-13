import Foundation

public struct WorldGraphValidationIssue: Equatable, Sendable {
    public var message: String
}

public struct WorldGraphValidationResult: Equatable, Sendable {
    public var worldID: String
    public var issues: [WorldGraphValidationIssue]

    public var isValid: Bool {
        issues.isEmpty
    }

    public func reportMarkdown() -> String {
        var lines = ["# World Graph Validation: \(worldID)", ""]
        if issues.isEmpty {
            lines.append("No issues.")
        } else {
            for issue in issues {
                lines.append("- \(issue.message)")
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

public enum WorldGraphValidator {
    public static func validateIfPresent(
        resourcesRoot: URL,
        maps: [TiledMap],
        worldID: String? = nil
    ) throws -> [WorldGraphValidationResult] {
        let worldsRoot = resourcesRoot.appending(path: "Data/worlds")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: worldsRoot,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        let decoder = JSONDecoder()
        if let worldID {
            let selectedURL = worldsRoot.appending(path: "\(worldID).json")
            guard FileManager.default.fileExists(atPath: selectedURL.path) else {
                return []
            }
            let graph = try decoder.decode(
                ChapterWorldGraph.self,
                from: Data(contentsOf: selectedURL)
            )
            return [validate(graph, maps: maps)]
        }

        let graphs = try contents
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { url in
                try decoder.decode(ChapterWorldGraph.self, from: Data(contentsOf: url))
            }
        return graphs.map { validate($0, maps: maps) }
    }

    static func validate(_ graph: ChapterWorldGraph, maps: [TiledMap]) -> WorldGraphValidationResult {
        let mapGroups = Dictionary(grouping: maps, by: \.areaID)
        let mapIndex = mapGroups.compactMapValues(\.first)
        let graphAreaIDs = graph.areas.map(\.id)
        let graphAreaIDSet = Set(graphAreaIDs)
        let spawnIndex = mapGroups.mapValues { maps in
            Set(maps.flatMap { $0.objectGroups["spawn", default: []].compactMap { $0.properties["id"] } })
        }
        var issues: [WorldGraphValidationIssue] = []

        for duplicate in mapGroups.filter({ $0.value.count > 1 }).keys.sorted() {
            issues.append(WorldGraphValidationIssue(message: "Duplicate TMX map area id: \(duplicate)"))
        }
        for duplicate in duplicates(in: graphAreaIDs) {
            issues.append(WorldGraphValidationIssue(message: "Duplicate world area id: \(duplicate)"))
        }
        if !graphAreaIDSet.contains(graph.startAreaId) {
            issues.append(WorldGraphValidationIssue(message: "Missing start area: \(graph.startAreaId)"))
        }
        if !(spawnIndex[graph.startAreaId]?.contains(graph.startSpawnId) ?? false) {
            issues.append(WorldGraphValidationIssue(message: "Missing start spawn: \(graph.startAreaId).\(graph.startSpawnId)"))
        }

        for area in graph.areas {
            if mapIndex[area.id] == nil {
                issues.append(WorldGraphValidationIssue(message: "World area has no TMX map: \(area.id)"))
            }
            for exit in area.exits {
                if !graphAreaIDSet.contains(exit.targetAreaId) {
                    issues.append(WorldGraphValidationIssue(message: "World exit \(area.id).\(exit.id) targets missing area: \(exit.targetAreaId)"))
                }
                if !(spawnIndex[exit.targetAreaId]?.contains(exit.targetSpawnId) ?? false) {
                    issues.append(WorldGraphValidationIssue(message: "World exit \(area.id).\(exit.id) targets missing spawn: \(exit.targetAreaId).\(exit.targetSpawnId)"))
                }
            }
        }

        for map in maps where graphAreaIDSet.contains(map.areaID) {
            for exit in map.objectGroups["exit", default: []] {
                guard let targetAreaID = exit.properties["targetAreaId"] else { continue }
                if !graphAreaIDSet.contains(targetAreaID) {
                    issues.append(WorldGraphValidationIssue(message: "TMX exit \(map.areaID).\(exit.tiledID) targets area outside world graph: \(targetAreaID)"))
                }
            }
        }

        let reachable = reachableAreas(from: graph.startAreaId, in: graph)
        for areaID in graphAreaIDSet.subtracting(reachable).sorted() {
            issues.append(WorldGraphValidationIssue(message: "World area is disconnected from start: \(areaID)"))
        }

        return WorldGraphValidationResult(worldID: graph.id, issues: issues)
    }

    private static func reachableAreas(from start: String, in graph: ChapterWorldGraph) -> Set<String> {
        let adjacency = Dictionary(grouping: graph.areas, by: \.id).mapValues { areas in
            Set(areas.flatMap { $0.exits.map(\.targetAreaId) })
        }
        var visited: Set<String> = []
        var queue = [start]

        while let areaID = queue.first {
            queue.removeFirst()
            guard visited.insert(areaID).inserted else { continue }
            queue.append(contentsOf: adjacency[areaID, default: []].subtracting(visited).sorted())
        }

        return visited
    }

    private static func duplicates(in values: [String]) -> [String] {
        var seen: Set<String> = []
        var duplicates: Set<String> = []

        for value in values where !seen.insert(value).inserted {
            duplicates.insert(value)
        }

        return duplicates.sorted()
    }
}

struct ChapterWorldGraph: Decodable, Equatable, Sendable {
    var id: String
    var title: String
    var startAreaId: String
    var startSpawnId: String
    var areas: [ChapterWorldArea]
}

struct ChapterWorldArea: Decodable, Equatable, Sendable {
    var id: String
    var displayName: String
    var biome: String
    var mapPath: String
    var exits: [ChapterWorldExit]
}

struct ChapterWorldExit: Decodable, Equatable, Sendable {
    var id: String
    var targetAreaId: String
    var targetSpawnId: String
}
