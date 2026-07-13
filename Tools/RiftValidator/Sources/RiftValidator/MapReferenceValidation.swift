import Foundation

public struct MapReferenceValidationIssue: Equatable, Sendable {
    public var message: String
}

public struct MapReferenceValidationResult: Equatable, Sendable {
    public var issues: [MapReferenceValidationIssue]

    public var isValid: Bool {
        issues.isEmpty
    }

    public func reportMarkdown() -> String {
        var lines = ["# Map Reference Validation", ""]
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

public enum MapReferenceValidator {
    public static func validateIfPresent(resourcesRoot: URL, maps: [TiledMap]) throws -> MapReferenceValidationResult? {
        let dataRoot = resourcesRoot.appending(path: "Data")
        guard FileManager.default.fileExists(atPath: dataRoot.path) else { return nil }

        let encounters = try ids(from: dataRoot.appending(path: "encounters.json"))
        let items = try ids(from: dataRoot.appending(path: "items.json"))
        let dialogs = try ids(from: dataRoot.appending(path: "dialogs.json"))
        let npcsURL = dataRoot.appending(path: "npcs.json")
        let npcs = FileManager.default.fileExists(atPath: npcsURL.path)
            ? try ids(from: npcsURL)
            : []
        var issues: [MapReferenceValidationIssue] = []

        for map in maps {
            for object in map.objectGroups["encounter", default: []] {
                guard let encounterID = object.properties["encounterId"], !encounters.contains(encounterID) else { continue }
                issues.append(MapReferenceValidationIssue(message: "\(map.areaID) encounter object \(object.tiledID) references missing encounter: \(encounterID)"))
            }
            for object in map.objectGroups["item", default: []] {
                guard let itemID = object.properties["itemId"], !items.contains(itemID) else { continue }
                issues.append(MapReferenceValidationIssue(message: "\(map.areaID) item object \(object.tiledID) references missing item: \(itemID)"))
            }
            for object in map.objectGroups["npc", default: []] {
                if let actorID = object.properties["actorId"], !npcs.isEmpty, !npcs.contains(actorID) {
                    issues.append(MapReferenceValidationIssue(message: "\(map.areaID) npc object \(object.tiledID) references missing npc: \(actorID)"))
                }
                if let dialogID = object.properties["dialogId"], !dialogs.contains(dialogID) {
                    issues.append(MapReferenceValidationIssue(message: "\(map.areaID) npc object \(object.tiledID) references missing dialog: \(dialogID)"))
                }
            }
            for object in map.objectGroups["trigger", default: []] {
                guard let action = object.properties["action"],
                      let dialogID = action.removingPrefix("dialogue:")
                else { continue }
                if !dialogs.contains(dialogID) {
                    issues.append(MapReferenceValidationIssue(message: "\(map.areaID) trigger object \(object.tiledID) references missing dialog: \(dialogID)"))
                }
            }
        }

        return MapReferenceValidationResult(issues: issues)
    }

    private static func ids(from url: URL) throws -> Set<String> {
        let records = try JSONDecoder().decode([IDRecord].self, from: Data(contentsOf: url))
        return Set(records.map(\.id))
    }
}

private struct IDRecord: Decodable {
    var id: String
}

private extension String {
    func removingPrefix(_ prefix: String) -> String? {
        guard hasPrefix(prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }
}
