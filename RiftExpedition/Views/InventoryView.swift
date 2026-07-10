import RiftCore
import SwiftUI

enum InventoryTab: String, CaseIterable, Identifiable {
    case equipment = "装备与属性"
    case skills = "技能"

    var id: String { rawValue }
}

struct InventoryView: View {
    let viewModel: InventoryViewModel
    let onClose: () -> Void
    private let initialTab: InventoryTab

    @State private var selectedItemID: String?
    @State private var selectedTab: InventoryTab

    private let gridColumns = [GridItem(.adaptive(minimum: 72, maximum: 72), spacing: 12)]

    init(
        viewModel: InventoryViewModel,
        onClose: @escaping () -> Void,
        initialTab: InventoryTab = .equipment
    ) {
        self.viewModel = viewModel
        self.onClose = onClose
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        RiftPanelScaffold(
            title: "队伍档案",
            subtitle: "共享背包、装备与技能始终同步到当前队伍。",
            closeLabel: "返回探索",
            onClose: onClose,
            maxWidth: 900
        ) {
            HStack(spacing: 8) {
                ForEach(InventoryTab.allCases) { tab in
                    Button(tab.rawValue) {
                        selectedTab = tab
                    }
                    .buttonStyle(RiftTabButtonStyle(isSelected: selectedTab == tab))
                }
            }

            switch selectedTab {
            case .equipment:
                HStack(alignment: .top, spacing: 24) {
                    partyPanel
                    itemPanel
                }
            case .skills:
                skillPanel
            }

            Text(viewModel.statusText)
                .font(.callout.weight(.semibold))
                .foregroundStyle(RiftPalette.bannerRed)
        }
    }

    private var partyPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("队伍")
                .font(.headline)
                .foregroundStyle(RiftPalette.textBrown)

            HStack(spacing: 8) {
                ForEach(viewModel.party) { actor in
                    Button(actor.displayName) {
                        viewModel.selectActor(id: actor.id)
                    }
                    .buttonStyle(RiftTabButtonStyle(isSelected: viewModel.selectedActorID == actor.id))
                    .accessibilityLabel("查看角色 \(actor.displayName)")
                }
            }

            if let actor = viewModel.selectedActor {
                CharacterSheetView(viewModel: viewModel, actor: actor)
            } else {
                Text("没有可查看的角色。")
                    .foregroundStyle(RiftPalette.textBrownLight)
            }
        }
        .frame(width: 300, alignment: .leading)
    }

    private var itemPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("共享背包")
                .font(.headline)
                .foregroundStyle(RiftPalette.textBrown)

            if viewModel.inventoryRows.isEmpty {
                Text("背包为空。")
                    .foregroundStyle(RiftPalette.textBrownLight)
            } else {
                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                    ForEach(viewModel.inventoryRows) { row in
                        itemSlotButton(row)
                    }
                }

                if let activeRow = activeRow {
                    selectedItemBar(activeRow)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var skillPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ForEach(viewModel.party) { actor in
                    Button(actor.displayName) {
                        viewModel.selectActor(id: actor.id)
                    }
                    .buttonStyle(RiftTabButtonStyle(isSelected: viewModel.selectedActorID == actor.id))
                }
            }

            if let actor = viewModel.selectedActor {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        RiftActorPortrait(classID: actor.classID, size: 72)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(actor.displayName)
                                .font(.title2.weight(.heavy))
                                .foregroundStyle(RiftPalette.textBrown)
                            Text("已掌握 \(viewModel.skills(for: actor).count) 个技能")
                                .font(.callout)
                                .foregroundStyle(RiftPalette.textBrownLight)
                        }
                    }

                    let skills = viewModel.skills(for: actor)
                    if skills.isEmpty {
                        Text("尚未学会技能。")
                            .foregroundStyle(RiftPalette.textBrownLight)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 12)], spacing: 12) {
                            ForEach(skills) { skill in
                                skillCard(skill)
                            }
                        }
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(RiftPalette.parchmentShade)
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(RiftPalette.outline, lineWidth: 2))
                )
            }
        }
    }

    private var activeRow: InventoryItemRow? {
        let rows = viewModel.inventoryRows
        if let selectedItemID, let match = rows.first(where: { $0.id == selectedItemID }) {
            return match
        }
        return rows.first
    }

    private func item(for row: InventoryItemRow) -> ItemDefinition? {
        viewModel.itemDefinitions.first { $0.id == row.id }
    }

    private func itemSlotButton(_ row: InventoryItemRow) -> some View {
        let definition = item(for: row)
        let isSelected = activeRow?.id == row.id

        return Button {
            selectedItemID = row.id
        } label: {
            RiftItemGridSlot(
                icon: definition.map(RiftItemIconography.icon(for:)),
                tint: definition.map(RiftItemIconography.tint(for:)) ?? RiftPalette.textBrownLight,
                quantity: row.count,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(row.displayName)，数量 \(row.count)")
    }

    private func selectedItemBar(_ row: InventoryItemRow) -> some View {
        let definition = item(for: row)

        return HStack(spacing: 12) {
            RiftItemGridSlot(
                icon: definition.map(RiftItemIconography.icon(for:)),
                tint: definition.map(RiftItemIconography.tint(for:)) ?? RiftPalette.textBrownLight,
                quantity: row.count
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayName)
                    .font(.headline)
                    .foregroundStyle(RiftPalette.textBrown)
                Text(row.slotName ?? "非装备")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RiftPalette.textBrownLight)
                if let definition = item(for: row) {
                    Text(itemSummary(definition))
                        .font(.caption)
                        .foregroundStyle(RiftPalette.textBrownLight)
                }
            }

            Spacer()

            Text("数量 \(row.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(RiftPalette.textBrownLight)

            Button("装备给 \(viewModel.selectedActor?.displayName ?? "角色")") {
                viewModel.equip(itemID: row.id)
            }
            .buttonStyle(RiftPrimaryButtonStyle())
            .disabled(row.slotName == nil)
            .accessibilityLabel("装备 \(row.displayName)")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(RiftPalette.parchmentShade)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(RiftPalette.outline, lineWidth: 2))
        )
    }

    private func skillCard(_ skill: CharacterSkillRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(RiftPalette.bannerRed)
                Text(skill.displayName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(RiftPalette.textBrown)
                Spacer()
                Text("\(skill.actionPointCost) AP")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RiftPalette.bannerRed, in: Capsule())
            }
            HStack {
                Label("\(skill.range, format: .number.precision(.fractionLength(0))) 格", systemImage: "ruler")
                Spacer()
                Text(skill.targetName)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(RiftPalette.textBrownLight)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(RiftPalette.parchment)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(RiftPalette.outline.opacity(0.5), lineWidth: 1.5))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("技能 \(skill.displayName)，消耗 \(skill.actionPointCost) AP，距离 \(skill.range)，目标 \(skill.targetName)")
    }

    private func itemSummary(_ item: ItemDefinition) -> String {
        guard let equipment = item.equipment else {
            return item.kind == .consumable ? "战斗中使用" : "任务物品"
        }
        let modifiers = equipment.modifiers
        let values = [
            modifiers.maxHealth == 0 ? nil : "生命 \(modifiers.maxHealth > 0 ? "+" : "")\(modifiers.maxHealth)",
            modifiers.attack == 0 ? nil : "攻击 \(modifiers.attack > 0 ? "+" : "")\(modifiers.attack)",
            modifiers.defense == 0 ? nil : "防御 \(modifiers.defense > 0 ? "+" : "")\(modifiers.defense)",
            modifiers.evasion == 0 ? nil : "闪避 \(modifiers.evasion > 0 ? "+" : "")\(modifiers.evasion)",
            modifiers.magic == 0 ? nil : "魔法 \(modifiers.magic > 0 ? "+" : "")\(modifiers.magic)"
        ]
        return values.compactMap { $0 }.joined(separator: " · ").isEmpty ? "无额外属性" : values.compactMap { $0 }.joined(separator: " · ")
    }
}
