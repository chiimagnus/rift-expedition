public enum Attribute: String, Codable, CaseIterable, Sendable {
    case maxHealth
    case attack
    case defense
    case evasion
    case magic
}

public enum AttributePointError: Error, Equatable, Sendable {
    case nonPositiveAmount(Int)
    case insufficientPoints(required: Int, available: Int)
}

public enum AttributePoints {
    public static func allocate(_ amount: Int, to attribute: Attribute, actor: inout Actor) throws {
        guard amount > 0 else {
            throw AttributePointError.nonPositiveAmount(amount)
        }
        guard actor.unspentAttributePoints >= amount else {
            throw AttributePointError.insufficientPoints(required: amount, available: actor.unspentAttributePoints)
        }

        actor.unspentAttributePoints -= amount
        switch attribute {
        case .maxHealth:
            actor.stats.maxHealth += amount * 5
            actor.stats.health += amount * 5
        case .attack:
            actor.stats.attack += amount
        case .defense:
            actor.stats.defense += amount
        case .evasion:
            actor.stats.evasion += amount
        case .magic:
            actor.stats.magic += amount
        }
    }
}
