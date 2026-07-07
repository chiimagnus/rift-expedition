import RiftCore

enum ActorVisualIDResolver {
    static func visualID(for actor: Actor) -> String {
        switch actor.kind {
        case .player:
            playerVisualID(classID: actor.classID)
        case .npc:
            npcVisualID(actorID: actor.id)
        case .humanEnemy:
            humanEnemyVisualID(classID: actor.classID, level: actor.level)
        case .animal:
            "enemy_beast_animal"
        case .monster:
            actor.level >= 3 ? "enemy_beast_rift" : "enemy_beast_tainted"
        }
    }

    private static func playerVisualID(classID: String?) -> String {
        switch classID {
        case "archer":
            "actor_archer"
        case "mage":
            "actor_mage"
        case "rogue":
            "actor_rogue"
        default:
            "actor_warrior"
        }
    }

    static func npcVisualID(actorID: String) -> String {
        switch actorID {
        case "elder", "mayor":
            "npc_mayor"
        case "fiance":
            "npc_fiance"
        case "gate_guard":
            "npc_gate_guard"
        case "healer":
            "npc_healer"
        default:
            "npc_mayor"
        }
    }

    private static func humanEnemyVisualID(classID: String?, level: Int) -> String {
        if level >= 4 {
            return "enemy_human_elite"
        }
        return classID == "archer" ? "enemy_human_ranged" : "enemy_human_melee"
    }
}
