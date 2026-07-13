public enum SkillEffect: Codable, Equatable, Sendable {
    case damage(Int)
    case heal(Int)
    case applyStatus(statusID: String, durationTurns: Int)
    case createSurface(surfaceID: String, durationTurns: Int)
}

public struct ResolvedStatusEffect: Equatable, Sendable {
    public var statusID: String
    public var durationTurns: Int

    public init(statusID: String, durationTurns: Int) {
        self.statusID = statusID
        self.durationTurns = durationTurns
    }
}

public struct ResolvedSurfaceEffect: Equatable, Sendable {
    public var surfaceID: String
    public var durationTurns: Int

    public init(surfaceID: String, durationTurns: Int) {
        self.surfaceID = surfaceID
        self.durationTurns = durationTurns
    }
}

public struct SkillResolution: Equatable, Sendable {
    public var didDodge: Bool
    public var appliedStatuses: [ResolvedStatusEffect]
    public var createdSurfaces: [ResolvedSurfaceEffect]

    public init(
        didDodge: Bool = false,
        appliedStatuses: [ResolvedStatusEffect] = [],
        createdSurfaces: [ResolvedSurfaceEffect] = []
    ) {
        self.didDodge = didDodge
        self.appliedStatuses = appliedStatuses
        self.createdSurfaces = createdSurfaces
    }
}
