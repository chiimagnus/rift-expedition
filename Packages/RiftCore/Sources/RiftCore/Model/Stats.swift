public struct Stats: Codable, Equatable, Sendable {
    public var maxHealth: Int
    public var health: Int
    public var attack: Int
    public var defense: Int
    public var evasion: Int
    public var magic: Int
    public var maxActionPoints: Int
    public var actionPoints: Int

    public init(
        maxHealth: Int,
        health: Int,
        attack: Int,
        defense: Int,
        evasion: Int,
        magic: Int,
        maxActionPoints: Int,
        actionPoints: Int
    ) {
        self.maxHealth = maxHealth
        self.health = health
        self.attack = attack
        self.defense = defense
        self.evasion = evasion
        self.magic = magic
        self.maxActionPoints = maxActionPoints
        self.actionPoints = actionPoints
    }
}
