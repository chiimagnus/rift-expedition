import Observation
import RiftCore

struct SaveSlotRow: Equatable, Identifiable {
    var slot: SaveSlot
    var title: String
    var detail: String
    var canLoad: Bool
    var isCorrupt: Bool

    var id: String {
        "\(slot.kind.rawValue)-\(slot.index)"
    }
}

@MainActor
@Observable
final class SaveLoadViewModel {
    private let store: SaveGameStore
    @ObservationIgnored private let makeSave: @MainActor () -> SaveGame?
    @ObservationIgnored private let applySave: @MainActor (SaveGame) -> Void
    var rows: [SaveSlotRow] = []
    var message = "选择存档槽。"

    init(
        store: SaveGameStore,
        makeSave: @escaping @MainActor () -> SaveGame?,
        applySave: @escaping @MainActor (SaveGame) -> Void
    ) {
        self.store = store
        self.makeSave = makeSave
        self.applySave = applySave
        refresh()
    }

    func refresh() {
        let slots = SaveSlotPolicy.manualSlots + SaveSlotPolicy.autoSlots
        let results = store.readResults(for: slots)
        rows = slots.map { slot in
            row(for: slot, result: results[slot])
        }
    }

    func saveManual(slot: SaveSlot) {
        guard slot.kind == .manual else {
            message = "请选择手动存档槽。"
            return
        }
        guard let save = makeSave() else {
            message = "当前没有可保存的队伍。"
            return
        }

        do {
            try store.write(save, to: slot, safety: .safe)
            message = "\(slotTitle(slot)) 已保存。"
            refresh()
        } catch {
            message = readableError(error)
        }
    }

    func requestAutosave(slot: SaveSlot = .auto(1), safety: SaveSafety) {
        guard slot.kind == .auto else {
            message = "请选择自动存档槽。"
            return
        }
        guard let save = makeSave() else {
            message = "当前没有可自动保存的队伍。"
            return
        }

        do {
            try store.write(save, to: slot, safety: safety)
            message = "\(slotTitle(slot)) 已自动保存。"
            refresh()
        } catch {
            message = readableError(error)
        }
    }

    func load(slot: SaveSlot) {
        do {
            let save = try store.read(slot)
            applySave(save)
            message = "\(slotTitle(slot)) 已读取。"
            refresh()
        } catch {
            message = readableReadError(error)
            refresh()
        }
    }

    private func row(for slot: SaveSlot, result: SaveSlotReadResult?) -> SaveSlotRow {
        guard let result else {
            return SaveSlotRow(slot: slot, title: slotTitle(slot), detail: "空槽", canLoad: false, isCorrupt: false)
        }

        if let save = result.save {
            return SaveSlotRow(
                slot: slot,
                title: slotTitle(slot),
                detail: "区域 \(save.currentAreaID) · 队伍 \(save.party.count) 人 · v\(save.schemaVersion)",
                canLoad: true,
                isCorrupt: false
            )
        }

        return SaveSlotRow(slot: slot, title: slotTitle(slot), detail: "损坏存档：无法读取", canLoad: false, isCorrupt: true)
    }

    private func slotTitle(_ slot: SaveSlot) -> String {
        switch slot.kind {
        case .manual:
            "手动槽 \(slot.index)"
        case .auto:
            "自动槽 \(slot.index)"
        }
    }

    private func readableError(_ error: Error) -> String {
        if let saveError = error as? SaveSlotError {
            switch saveError {
            case .invalidManualSlot(_):
                return "手动存档槽无效。"
            case .invalidAutoSlot(_):
                return "自动存档槽无效。"
            case .unsafeAutosave:
                return "自动存档被拒绝：当前不是安全点。"
            }
        }
        return "存档失败。"
    }

    private func readableReadError(_ error: Error) -> String {
        if error is DecodingError {
            return "存档已损坏，无法读取。"
        }
        return "读取失败：该存档槽为空或不可用。"
    }
}
