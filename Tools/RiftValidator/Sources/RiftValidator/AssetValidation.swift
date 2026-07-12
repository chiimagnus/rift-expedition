import Foundation

public struct AssetManifestEntry: Codable, Equatable, Sendable {
    public var id: String
    public var path: String
    public var type: String
    public var source: String
    public var license: String
    public var downloadedAt: String
    public var author: String
}

public struct AssetValidationIssue: Equatable, Sendable {
    public var message: String
}

public struct AssetValidationResult: Equatable, Sendable {
    public var entries: [AssetManifestEntry]
    public var issues: [AssetValidationIssue]

    public var isValid: Bool {
        issues.isEmpty
    }

    public func reportMarkdown() -> String {
        var lines = ["# Asset Validation", ""]
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

private struct ActorAnimationCatalog: Decodable, Sendable {
    var version: Int
    var frameSize: FrameSize
    var directions: [String]
    var actions: [String: ActorAnimationAction]
    var sprites: [ActorAnimationSprite]
}

private struct FrameSize: Decodable, Sendable {
    var width: Int
    var height: Int
}

private struct ActorAnimationAction: Decodable, Sendable {
    var startColumn: Int
    var frameCount: Int
}

private struct ActorAnimationSprite: Decodable, Sendable {
    var visualID: String
    var sheet: String
}

public enum AssetValidator {
    public static let allowedLicenses: Set<String> = ["CC0", "self-made", "ai-static"]
    private static let bannedIDFragments = ["placeholder", "temp", "graybox"]
    private static let animationConfigPath = "Assets/actor-animations.json"
    private static let expectedAnimationFrameSize = FrameSize(width: 96, height: 96)
    private static let expectedAnimationSheetSize = FrameSize(width: 1152, height: 384)
    private static let expectedDirections = ["down", "left", "right", "up"]
    private static let expectedActions: [String: (startColumn: Int, frameCount: Int)] = [
        "idle": (0, 3),
        "walk": (3, 3),
        "attack": (6, 3),
        "hurt": (9, 3)
    ]

    public static func validate(resourcesRoot: URL) throws -> AssetValidationResult {
        let manifestURL = resourcesRoot.appending(path: "Assets/assets-manifest.json")
        let data = try Data(contentsOf: manifestURL)
        let entries = try JSONDecoder().decode([AssetManifestEntry].self, from: data)
        return AssetValidationResult(entries: entries, issues: collectIssues(entries: entries, resourcesRoot: resourcesRoot))
    }

    public static func collectIssues(entries: [AssetManifestEntry], resourcesRoot: URL) -> [AssetValidationIssue] {
        var issues: [AssetValidationIssue] = []
        var seenIDs: Set<String> = []
        let manifestEntriesByPath = Dictionary(grouping: entries, by: \.path)

        for entry in entries {
            if !seenIDs.insert(entry.id).inserted {
                issues.append(AssetValidationIssue(message: "Duplicate asset id: \(entry.id)"))
            }
            if !allowedLicenses.contains(entry.license) {
                issues.append(AssetValidationIssue(message: "Disallowed asset license for \(entry.id): \(entry.license)"))
            }
            let lowercaseID = entry.id.lowercased()
            for fragment in bannedIDFragments where lowercaseID.contains(fragment) {
                issues.append(AssetValidationIssue(message: "Formal asset id contains banned fragment '\(fragment)': \(entry.id)"))
            }
            if !FileManager.default.fileExists(atPath: resourcesRoot.appending(path: entry.path).path) {
                issues.append(AssetValidationIssue(message: "Missing asset file for \(entry.id): \(entry.path)"))
            }
        }

        issues.append(contentsOf: collectActorAnimationIssues(
            resourcesRoot: resourcesRoot,
            manifestEntriesByPath: manifestEntriesByPath
        ))

        return issues
    }

    private static func collectActorAnimationIssues(
        resourcesRoot: URL,
        manifestEntriesByPath: [String: [AssetManifestEntry]]
    ) -> [AssetValidationIssue] {
        let configURL = resourcesRoot.appending(path: animationConfigPath)
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return []
        }

        do {
            let catalog = try JSONDecoder().decode(ActorAnimationCatalog.self, from: Data(contentsOf: configURL))
            return validateActorAnimationCatalog(
                catalog,
                resourcesRoot: resourcesRoot,
                manifestEntriesByPath: manifestEntriesByPath
            )
        } catch {
            return [AssetValidationIssue(message: "Invalid actor animation config \(animationConfigPath): \(error)")]
        }
    }

    private static func validateActorAnimationCatalog(
        _ catalog: ActorAnimationCatalog,
        resourcesRoot: URL,
        manifestEntriesByPath: [String: [AssetManifestEntry]]
    ) -> [AssetValidationIssue] {
        var issues: [AssetValidationIssue] = []

        if catalog.version != 1 {
            issues.append(AssetValidationIssue(message: "\(animationConfigPath) version must be 1, got \(catalog.version)"))
        }
        if catalog.frameSize.width != expectedAnimationFrameSize.width || catalog.frameSize.height != expectedAnimationFrameSize.height {
            issues.append(AssetValidationIssue(message: "\(animationConfigPath) frameSize must be 96x96, got \(catalog.frameSize.width)x\(catalog.frameSize.height)"))
        }
        if catalog.directions != expectedDirections {
            issues.append(AssetValidationIssue(message: "\(animationConfigPath) directions must be \(expectedDirections), got \(catalog.directions)"))
        }
        let actionNames = Set(catalog.actions.keys)
        let expectedActionNames = Set(expectedActions.keys)
        if actionNames != expectedActionNames {
            issues.append(AssetValidationIssue(message: "\(animationConfigPath) actions must be \(expectedActionNames.sorted()), got \(actionNames.sorted())"))
        }

        var usedColumns: Set<Int> = []
        for actionName in expectedActions.keys.sorted() {
            guard let expected = expectedActions[actionName] else { continue }
            guard let action = catalog.actions[actionName] else {
                issues.append(AssetValidationIssue(message: "\(animationConfigPath) missing action: \(actionName)"))
                continue
            }
            if action.frameCount != expected.frameCount {
                issues.append(AssetValidationIssue(message: "\(animationConfigPath) action \(actionName) frameCount must be \(expected.frameCount), got \(action.frameCount)"))
            }
            if action.startColumn != expected.startColumn {
                issues.append(AssetValidationIssue(message: "\(animationConfigPath) action \(actionName) startColumn must be \(expected.startColumn), got \(action.startColumn)"))
            }

            let columns = action.startColumn..<(action.startColumn + action.frameCount)
            for column in columns {
                if !usedColumns.insert(column).inserted {
                    issues.append(AssetValidationIssue(message: "\(animationConfigPath) action \(actionName) overlaps column \(column)"))
                }
            }
        }

        var seenVisualIDs: Set<String> = []
        for sprite in catalog.sprites {
            if !seenVisualIDs.insert(sprite.visualID).inserted {
                issues.append(AssetValidationIssue(message: "Duplicate actor animation visualID: \(sprite.visualID)"))
            }
            let expectedSheet = "Assets/Characters/\(sprite.visualID)_anim.png"
            if sprite.sheet != expectedSheet {
                issues.append(AssetValidationIssue(message: "Actor animation \(sprite.visualID) sheet must be \(expectedSheet), got \(sprite.sheet)"))
            }
            let sheetURL = resourcesRoot.appending(path: sprite.sheet)
            if !FileManager.default.fileExists(atPath: sheetURL.path) {
                issues.append(AssetValidationIssue(message: "Actor animation \(sprite.visualID) missing sheet: \(sprite.sheet)"))
                continue
            }
            if !(manifestEntriesByPath[sprite.sheet]?.contains(where: { $0.type == "spritesheet" }) ?? false) {
                issues.append(AssetValidationIssue(message: "Actor animation \(sprite.visualID) sheet not registered as spritesheet in assets-manifest.json: \(sprite.sheet)"))
            }
            guard let imageSize = pngSize(url: sheetURL) else {
                issues.append(AssetValidationIssue(message: "Actor animation \(sprite.visualID) unreadable PNG sheet: \(sprite.sheet)"))
                continue
            }
            if imageSize.width != expectedAnimationSheetSize.width || imageSize.height != expectedAnimationSheetSize.height {
                issues.append(AssetValidationIssue(message: "Actor animation \(sprite.visualID) sheet \(sprite.sheet) must be 1152x384, got \(imageSize.width)x\(imageSize.height)"))
            }
        }

        return issues
    }

    private static func pngSize(url: URL) -> FrameSize? {
        guard let data = try? Data(contentsOf: url), data.count >= 24 else { return nil }
        let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        guard Array(data.prefix(8)) == signature else { return nil }

        func integer(at offset: Int) -> Int {
            data[offset..<(offset + 4)].reduce(0) { ($0 << 8) | Int($1) }
        }
        return FrameSize(width: integer(at: 16), height: integer(at: 20))
    }
}
