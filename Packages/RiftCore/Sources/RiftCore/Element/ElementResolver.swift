public enum ElementResolver {
    public static func surfaceAfterApplying(_ incoming: SurfaceType, to existing: SurfaceType?) -> SurfaceType? {
        switch (existing, incoming) {
        case (.some(.oil), .fire), (.some(.poison), .fire):
            .fire
        case (.some(.fire), .water):
            .water
        default:
            incoming
        }
    }

    public static func applySurface(_ surface: SurfaceType, to actor: inout Actor) {
        switch surface {
        case .water:
            removeStatus(.burning, from: &actor)
            applyStatus(.wet, turns: 2, to: &actor)
        case .oil:
            break
        case .poison:
            applyStatus(.poisoned, turns: 3, to: &actor)
        case .fire:
            removeStatus(.wet, from: &actor)
            applyStatus(.burning, turns: 2, to: &actor)
        }
    }

    public static func tickStatuses(on actor: inout Actor) {
        for status in actor.statuses {
            switch status.type {
            case .burning:
                actor.stats.health = max(0, actor.stats.health - 3)
            case .poisoned:
                actor.stats.health = max(0, actor.stats.health - 2)
            case .wet:
                break
            }
        }

        actor.statuses = actor.statuses
            .map { StatusEffect(type: $0.type, remainingTurns: $0.remainingTurns - 1) }
            .filter { $0.remainingTurns > 0 }
    }

    public static func applyStatus(_ status: StatusType, turns: Int, to actor: inout Actor) {
        guard turns > 0 else { return }
        removeStatus(status, from: &actor)
        actor.statuses.append(StatusEffect(type: status, remainingTurns: turns))
    }

    private static func removeStatus(_ status: StatusType, from actor: inout Actor) {
        actor.statuses.removeAll { $0.type == status }
    }
}
