import Foundation
import RiftCore

struct SaveGameStore {
    var directory: URL

    init(directory: URL = URL.documentsDirectory.appending(path: "RiftExpeditionSaves")) {
        self.directory = directory
    }

    func write(_ save: SaveGame, to slot: SaveSlot, safety: SaveSafety) throws {
        try SaveSlotPolicy.prepareWrite(to: slot, safety: safety)
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
