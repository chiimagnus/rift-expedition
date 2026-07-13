import Foundation
import RiftCore

struct SaveGameStore {
    var directory: URL

    init(directory: URL = URL.documentsDirectory.appending(path: "RiftExpeditionSaves")) {
        self.directory = directory
    }

    func write(_ save: SaveGame, to slot: SaveSlot, safety: SaveSafety) throws {
        try SaveSlotPolicy.prepareWrite(to: slot, safety: safety)
        try save.validate()
        try createDirectoryIfNeeded()
        let data = try JSONEncoder().encode(save)
        try data.write(to: fileURL(for: slot), options: .atomic)
    }

    func read(_ slot: SaveSlot) throws -> SaveGame {
        try SaveSlotPolicy.validate(slot)
        let data = try Data(contentsOf: fileURL(for: slot))
        return try JSONDecoder().decode(SaveGame.self, from: data)
    }

    func readResult(for slot: SaveSlot) -> SaveSlotReadResult? {
        guard FileManager.default.fileExists(atPath: fileURL(for: slot).path) else {
            return nil
        }

        do {
            return SaveSlotReadResult(slot: slot, save: try read(slot), errorDescription: nil)
        } catch {
            return SaveSlotReadResult(slot: slot, save: nil, errorDescription: String(describing: error))
        }
    }

    func readResults(for slots: [SaveSlot]) -> [SaveSlot: SaveSlotReadResult] {
        Dictionary(uniqueKeysWithValues: slots.compactMap { slot in
            guard let result = readResult(for: slot) else { return nil }
            return (slot, result)
        })
    }

    func nextAutosaveSlot() -> SaveSlot {
        let modifiedAt = Dictionary(uniqueKeysWithValues: SaveSlotPolicy.autoSlots.compactMap { slot -> (SaveSlot, Date)? in
            let url = fileURL(for: slot)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            return (slot, attributes?[.modificationDate] as? Date ?? .distantPast)
        })
        return SaveSlotPolicy.nextAutosaveSlot(existingModifiedAt: modifiedAt)
    }

    func readableAutosavesNewestFirst() -> [(slot: SaveSlot, save: SaveGame)] {
        SaveSlotPolicy.autoSlots
            .compactMap { slot -> (slot: SaveSlot, save: SaveGame, modifiedAt: Date)? in
                let url = fileURL(for: slot)
                guard FileManager.default.fileExists(atPath: url.path), let save = try? read(slot) else {
                    return nil
                }

                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let modifiedAt = attributes?[.modificationDate] as? Date ?? .distantPast
                return (slot, save, modifiedAt)
            }
            .sorted { lhs, rhs in
                if lhs.modifiedAt == rhs.modifiedAt {
                    return lhs.slot.index < rhs.slot.index
                }
                return lhs.modifiedAt > rhs.modifiedAt
            }
            .map { (slot: $0.slot, save: $0.save) }
    }

    func writeRawData(_ data: Data, to slot: SaveSlot) throws {
        try SaveSlotPolicy.validate(slot)
        try createDirectoryIfNeeded()
        try data.write(to: fileURL(for: slot), options: .atomic)
    }

    func fileURL(for slot: SaveSlot) -> URL {
        directory.appending(path: "\(slot.kind.rawValue)-\(slot.index).json")
    }

    private func createDirectoryIfNeeded() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
