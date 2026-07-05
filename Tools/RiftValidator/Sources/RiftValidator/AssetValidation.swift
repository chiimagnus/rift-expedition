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

public enum AssetValidator {
    public static let allowedLicenses: Set<String> = ["CC0", "self-made", "ai-static"]
    private static let bannedIDFragments = ["placeholder", "temp", "graybox"]

    public static func validate(resourcesRoot: URL) throws -> AssetValidationResult {
        let manifestURL = resourcesRoot.appending(path: "Assets/assets-manifest.json")
        let data = try Data(contentsOf: manifestURL)
        let entries = try JSONDecoder().decode([AssetManifestEntry].self, from: data)
        return AssetValidationResult(entries: entries, issues: collectIssues(entries: entries, resourcesRoot: resourcesRoot))
    }

    public static func collectIssues(entries: [AssetManifestEntry], resourcesRoot: URL) -> [AssetValidationIssue] {
        var issues: [AssetValidationIssue] = []
        var seenIDs: Set<String> = []

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

        return issues
    }
}
