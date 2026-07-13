import CoreGraphics
import Foundation
import RiftCore

struct TriggeredEncounter: Equatable {
    var definition: EncounterDefinition
    var trigger: MapEncounterTrigger
}

struct EncounterTriggerService: Equatable {
    private let triggers: [MapEncounterTrigger]
    private let encountersByID: [String: EncounterDefinition]
    private(set) var triggeredTiledIDs: Set<Int>

    init(
        triggers: [MapEncounterTrigger],
        encounters: [EncounterDefinition],
        triggeredTiledIDs: Set<Int> = []
    ) {
        self.triggers = triggers
        encountersByID = Dictionary(uniqueKeysWithValues: encounters.map { ($0.id, $0) })
        self.triggeredTiledIDs = triggeredTiledIDs
    }

    func pendingEncounter(at position: CGPoint) -> TriggeredEncounter? {
        guard let trigger = triggers.first(where: { trigger in
            !triggeredTiledIDs.contains(trigger.tiledID)
                && trigger.contains(position)
                && encountersByID[trigger.encounterID] != nil
        }), let encounter = encountersByID[trigger.encounterID] else {
            return nil
        }
        return TriggeredEncounter(definition: encounter, trigger: trigger)
    }

    mutating func markTriggered(tiledID: Int) {
        triggeredTiledIDs.insert(tiledID)
    }

}
