import CoreGraphics
import Foundation
import RiftCore

struct EncounterDefinition: Codable, Equatable, Identifiable {
    var id: String
    var displayName: String
    var enemies: [Actor]
}

struct TriggeredEncounter: Equatable {
    var definition: EncounterDefinition
    var trigger: MapEncounterTrigger
}

struct EncounterTriggerService: Equatable {
    private let triggers: [MapEncounterTrigger]
    private let encountersByID: [String: EncounterDefinition]
    private(set) var triggeredEncounterIDs: Set<String> = []

    init(triggers: [MapEncounterTrigger], encounters: [EncounterDefinition]) {
        self.triggers = triggers
        var indexedEncounters: [String: EncounterDefinition] = [:]
        for encounter in encounters where indexedEncounters[encounter.id] == nil {
            indexedEncounters[encounter.id] = encounter
        }
        encountersByID = indexedEncounters
    }

    mutating func encounter(at position: CGPoint) -> EncounterDefinition? {
        triggeredEncounter(at: position)?.definition
    }

    mutating func triggeredEncounter(at position: CGPoint) -> TriggeredEncounter? {
        guard let trigger = triggers.first(where: { trigger in
            !triggeredEncounterIDs.contains(trigger.encounterID) && trigger.contains(position)
        }) else {
            return nil
        }

        triggeredEncounterIDs.insert(trigger.encounterID)
        guard let encounter = encountersByID[trigger.encounterID] else { return nil }
        return TriggeredEncounter(definition: encounter, trigger: trigger)
    }

    static func loadDefinitions(from bundle: Bundle = .main) -> [EncounterDefinition] {
        guard let url = bundle.url(forResource: "encounters", withExtension: "json", subdirectory: "Data"),
              let data = try? Data(contentsOf: url),
              let encounters = try? JSONDecoder().decode([EncounterDefinition].self, from: data)
        else {
            return []
        }
        return encounters
    }
}
