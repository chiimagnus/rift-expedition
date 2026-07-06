public enum AITendency: String, Codable, CaseIterable, Sendable {
    case melee
    case archer
    case mage
    case rogue

    public static func inferred(for actor: Actor, skills: [SkillDefinition]) -> AITendency {
        switch actor.classID {
        case "archer":
            return .archer
        case "mage":
            return .mage
        case "rogue":
            return .rogue
        default:
            break
        }

        if skills.contains(where: isElemental) {
            return .mage
        }
        if skills.contains(where: { $0.range >= 5.0 }) {
            return .archer
        }
        if actor.stats.evasion >= actor.stats.defense + 3 {
            return .rogue
        }
        return .melee
    }

    static func isElemental(_ skill: SkillDefinition) -> Bool {
        if !skill.canBeDodged {
            return true
        }
        return skill.effects.contains { effect in
            switch effect {
            case .applyStatus(_, _), .createSurface(_, _):
                return true
            default:
                return false
            }
        }
    }
}
