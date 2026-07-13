public enum SkillResolver {
    public static func resolve<R: RandomSource>(
        skill: SkillDefinition,
        casterID: String,
        targetID: String,
        context: TargetingContext,
        in state: inout BattleState,
        random: inout R
    ) throws -> SkillResolution {
        guard let caster = state.actor(id: casterID) else {
            throw BattleActionError.actorNotFound(casterID)
        }
        guard let target = state.actor(id: targetID) else {
            throw BattleActionError.actorNotFound(targetID)
        }
        try TargetingRules.validate(skill: skill, caster: caster, target: target, context: context)

        if skill.canBeDodged && random.roll(chancePercent: target.stats.evasion) {
            return SkillResolution(didDodge: true)
        }

        var resolution = SkillResolution()
        for effect in skill.effects {
            apply(effect, targetID: targetID, state: &state, resolution: &resolution)
        }
        return resolution
    }

    private static func apply(
        _ effect: SkillEffect,
        targetID: String,
        state: inout BattleState,
        resolution: inout SkillResolution
    ) {
        switch effect {
        case let .damage(amount):
            _ = state.updateActor(id: targetID) { actor in
                let damage = max(0, amount - actor.stats.defense)
                actor.stats.health = max(0, actor.stats.health - damage)
            }
        case let .heal(amount):
            _ = state.updateActor(id: targetID) { actor in
                actor.stats.health = min(actor.stats.maxHealth, actor.stats.health + max(0, amount))
            }
        case let .applyStatus(statusID, durationTurns):
            let resolved = ResolvedStatusEffect(statusID: statusID, durationTurns: durationTurns)
            resolution.appliedStatuses.append(resolved)
            if let status = StatusType(rawValue: statusID) {
                _ = state.updateActor(id: targetID) { actor in
                    ElementResolver.applyStatus(status, turns: durationTurns, to: &actor)
                }
            }
        case let .createSurface(surfaceID, durationTurns):
            resolution.createdSurfaces.append(
                ResolvedSurfaceEffect(surfaceID: surfaceID, durationTurns: durationTurns)
            )
        }
    }
}
