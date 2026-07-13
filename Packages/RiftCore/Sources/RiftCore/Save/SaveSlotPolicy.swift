import Foundation

public enum SaveSafety: String, Codable, Sendable {
    case safe
    case unsafe
}

public enum SaveSlotError: Error, Equatable, Sendable {
    case invalidManualSlot(Int)
    case invalidAutoSlot(Int)
    case unsafeAutosave
}

public struct SaveSlotReadResult: Equatable, Sendable {
    public var slot: SaveSlot
    public var save: SaveGame?
    public var errorDescription: String?

    public var isReadable: Bool {
        save != nil
    }

    public init(slot: SaveSlot, save: SaveGame?, errorDescription: String?) {
        self.slot = slot
        self.save = save
        self.errorDescription = errorDescription
    }
}

public enum SaveSlotPolicy {
    public static let maxManualSlots = 5
    public static let maxAutoSlots = 5

    public static var manualSlots: [SaveSlot] {
        (1...maxManualSlots).map(SaveSlot.manual)
    }

    public static var autoSlots: [SaveSlot] {
        (1...maxAutoSlots).map(SaveSlot.auto)
    }

    public static func validate(_ slot: SaveSlot) throws {
        switch slot.kind {
        case .manual where !(1...maxManualSlots).contains(slot.index):
            throw SaveSlotError.invalidManualSlot(slot.index)
        case .auto where !(1...maxAutoSlots).contains(slot.index):
            throw SaveSlotError.invalidAutoSlot(slot.index)
        default:
            break
        }
    }

    public static func prepareWrite(to slot: SaveSlot, safety: SaveSafety) throws {
        try validate(slot)
        if slot.kind == .auto && safety != .safe {
            throw SaveSlotError.unsafeAutosave
        }
    }

    public static func nextAutosaveSlot(existingModifiedAt: [SaveSlot: Date]) -> SaveSlot {
        if let emptySlot = autoSlots.first(where: { existingModifiedAt[$0] == nil }) {
            return emptySlot
        }

        return autoSlots.min { lhs, rhs in
            let lhsDate = existingModifiedAt[lhs] ?? .distantPast
            let rhsDate = existingModifiedAt[rhs] ?? .distantPast
            if lhsDate == rhsDate {
                return lhs.index < rhs.index
            }
            return lhsDate < rhsDate
        } ?? .auto(1)
    }

    public static func readSlots(from payloads: [SaveSlot: Data]) -> [SaveSlotReadResult] {
        let decoder = JSONDecoder()
        return payloads
            .sorted { lhs, rhs in
                lhs.key.kind.rawValue == rhs.key.kind.rawValue
                    ? lhs.key.index < rhs.key.index
                    : lhs.key.kind.rawValue < rhs.key.kind.rawValue
            }
            .map { slot, data in
                do {
                    return SaveSlotReadResult(slot: slot, save: try decoder.decode(SaveGame.self, from: data), errorDescription: nil)
                } catch {
                    return SaveSlotReadResult(slot: slot, save: nil, errorDescription: String(describing: error))
                }
            }
    }
}
