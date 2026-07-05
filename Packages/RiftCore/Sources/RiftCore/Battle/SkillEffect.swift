public enum SkillEffect: Codable, Equatable, Sendable {
    case damage(Int)
    case heal(Int)
    case applyStatus(statusID: String, durationTurns: Int)
    case createSurface(surfaceID: String, durationTurns: Int)
    case move(distance: Double)
    case summon(actorID: String)
}

public struct SkillResolution: Equatable, Sendable {
    public var didDodge: Bool
    public var appliedStatuses: [String]
    public var createdSurfaces: [String]
    public var summonedActorIDs: [String]
    public var movedDistance: Double

    public init(
        didDodge: Bool = false,
        appliedStatuses: [String] = [],
        createdSurfaces: [String] = [],
        summonedActorIDs: [String] = [],
        movedDistance: Double = 0
    ) {
        self.didDodge = didDodge
        self.appliedStatuses = appliedStatuses
        self.createdSurfaces = createdSurfaces
        self.summonedActorIDs = summonedActorIDs
        self.movedDistance = movedDistance
    }
}
