import RiftCore
import SwiftUI

enum InventoryTab: String, CaseIterable, Identifiable {
    case equipment = "装备与属性"
    case skills = "技能档案"

    var id: String { rawValue }
}

struct InventoryView: View {
    let viewModel: InventoryViewModel
    let onClose: () -> Void
    private let initialTab: InventoryTab

    @State private var selectedItemID: String?
    @State private var selectedTab: InventoryTab

    private let gridColumns = [GridItem(.adaptive(minimum: 72, maximum: 72), spacing: 10)]

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
            title: "远征队档案",
            subtitle: "调整装备、分配属性点，并查看队员掌握的战术能力。",
            closeLabel: "返回探索",
            onClose: onClose,
            maxWidth: 1_080
        ) {
            HStack(spacing: 9) {
                ForEach(InventoryTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.rawValue, systemImage: tab == .equipment ? "shield.lefthalf.filled" : "sparkles")
                    }
                    .buttonStyle(RiftTabButtonStyle(isSelected: selectedTab == tab))
                }
                Spacer()
                RiftStatusPill(text: "共享背包 \(viewModel.inventoryRows.reduce(0) { $0 + $1.count }) 件", tint: RiftPalette.riftBlue, icon: "shippingbox.fill")
            }

            switch selectedTab {
            case .equipment:
                HStack(alignment: .top, spacing: 18) {
                    partyPanel
                    itemPanel
                }
            case .skills:
                skillPanel
            }

            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(RiftPalette.riftBlue)
                Text(viewModel.statusText)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(RiftPalette.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(RiftPalette.riftBlue.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
    }

    private var partyPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            RiftSectionHeader("队员与装备", eyebrow: "PARTY LOADOUT", systemImage: "person.2.fill")

            HStack(spacing: 8) {
                ForEach(viewModel.party) { actor in
                    Button {
                        viewModel.selectActor(id: actor.id)
                    } label: {
                        HStack(spacing: 7) {
                            RiftActorPortrait(classID: actor.classID, size: 30, isActive: viewModel.selectedActorID == actor.id)
                            Text(actor.displayName)
                        }
                    }
                    .buttonStyle(RiftTabButtonStyle(isSelected: viewModel.selectedActorID == actor.id))
                    .accessibilityLabel("查看角色 \(actor.displayName)")
                }
            }

            if let actor = viewModel.selectedActor {
                CharacterSheetView(viewModel: viewModel, actor: actor)
            } else {
                Text("没有可查看的角色。")
                    .foregroundStyle(RiftPalette.muted)
            }
        }
        .frame(width: 350, alignment: .leading)
    }

    private var itemPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            RiftSectionHeader("共享背包", eyebrow: "INVENTORY", systemImage: "shippingbox.fill")

            if viewModel.inventoryRows.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 32))
                    Text("背包为空")
                        .font(.headline)
                    Text("探索、任务和战斗奖励会出现在这里。")
                        .font(.caption)
                }
                .foregroundStyle(RiftPalette.muted)
                .frame(maxWidth: .infinity, minHeight: 260)
                .background(RiftPalette.void.opacity(0.24), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                HStack(alignment: .top, spacing: 16) {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
                            ForEach(viewModel.inventoryRows) { row in
                                itemSlotButton(row)
                            }
                        }
                        .padding(2)
                    }
                    .frame(minWidth: 250, maxWidth: 300, minHeight: 310)

                    if let activeRow {
                        selectedItemDetail(activeRow)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var skillPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ForEach(viewModel.party) { actor in
                    Button {
                        viewModel.selectActor(id: actor.id)
                    } label: {
                        HStack(spacing: 7) {
                            RiftActorPortrait(classID: actor.classID, size: 30, isActive: viewModel.selectedActorID == actor.id)
                            Text(actor.displayName)
                        }
                    }
                    .buttonStyle(RiftTabButtonStyle(isSelected: viewModel.selectedActorID == actor.id))
                }
                Spacer()
                if let actor = viewModel.selectedActor {
                    RiftStatusPill(text: "已掌握 \(viewModel.skills(for: actor).count) 项", tint: RiftPalette.riftViolet, icon: "sparkles")
                }
            }

            if let actor = viewModel.selectedActor {
                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: 10) {
                        RiftActorPortrait(classID: actor.classID, size: 128, isActive: true)
                        Text(actor.displayName)
                            .font(.title2.weight(.black))
                            .foregroundStyle(RiftPalette.frost)
                        Text("等级 \(actor.level) · \(classLabel(actor.classID))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RiftPalette.muted)
                        HStack(spacing: 6) {
                            RiftStatusPill(text: "\(actor.stats.maxActionPoints) AP", tint: RiftPalette.ember)
                            RiftStatusPill(text: "魔法 \(actor.stats.magic)", tint: RiftPalette.riftBlue)
                        }
                    }
                    .padding(18)
                    .frame(width: 220)
                    .riftParchmentPanel(cornerRadius: 17)

                    let skills = viewModel.skills(for: actor)
                    if skills.isEmpty {
                        Text("尚未学会技能。")
                            .foregroundStyle(RiftPalette.muted)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 12)], spacing: 12) {
                                ForEach(skills) { skill in
                                    skillCard(skill)
                                }
                            }
                            .padding(2)
                        }
                        .frame(minHeight: 360)
                    }
                }
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
                tint: definition.map(RiftItemIconography.tint(for:)) ?? RiftPalette.muted,
                quantity: row.count,
                isSelected: isSelected,
                rarity: definition?.rarity
            )
        }
        .buttonStyle(.plain)
        .riftHoverLift()
        .accessibilityLabel("\(row.displayName)，数量 \(row.count)")
    }

    private func selectedItemDetail(_ row: InventoryItemRow) -> some View {
        let definition = item(for: row)
        let rarity = definition?.rarity
        let rarityTint = RiftRarityStyle.color(for: rarity)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                RiftItemGridSlot(
                    icon: definition.map(RiftItemIconography.icon(for:)),
                    tint: definition.map(RiftItemIconography.tint(for:)) ?? RiftPalette.muted,
                    quantity: row.count,
                    rarity: rarity
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.displayName)
                        .font(.title3.weight(.black))
                        .foregroundStyle(RiftPalette.frost)
                    HStack(spacing: 7) {
                        RiftStatusPill(text: RiftRarityStyle.name(for: rarity), tint: rarityTint)
                        RiftStatusPill(text: row.slotName ?? kindName(definition?.kind), tint: RiftPalette.steel)
                    }
                }
            }

            Text(definition?.description ?? "没有找到物品配置。")
                .font(.callout)
                .foregroundStyle(RiftPalette.muted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let definition {
                modifierGrid(definition)

                if let comparison = comparisonSummary(for: definition) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundStyle(RiftPalette.riftBlue)
                        Text(comparison)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiftPalette.muted)
                    }
                    .padding(10)
                    .background(RiftPalette.riftBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }

            Spacer(minLength: 8)

            HStack {
                Text("持有 ×\(row.count)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(RiftPalette.muted)
                Spacer()
                Button {
                    viewModel.equip(itemID: row.id)
                } label: {
                    Label("装备给 \(viewModel.selectedActor?.displayName ?? "角色")", systemImage: "checkmark.shield.fill")
                }
                .buttonStyle(RiftPrimaryButtonStyle())
                .disabled(row.slotName == nil)
                .accessibilityLabel("装备 \(row.displayName)")
            }
        }
        .padding(17)
        .frame(maxWidth: .infinity, minHeight: 310, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(LinearGradient(colors: [rarityTint.opacity(0.09), RiftPalette.panelRaised], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(rarityTint.opacity(0.42), lineWidth: 1.2))
        )
    }

    @ViewBuilder
    private func modifierGrid(_ item: ItemDefinition) -> some View {
        if let equipment = item.equipment {
            let modifiers = equipment.modifiers
            let values: [(String, Int, String)] = [
                ("生命", modifiers.maxHealth, "heart.fill"),
                ("攻击", modifiers.attack, "burst.fill"),
                ("防御", modifiers.defense, "shield.fill"),
                ("闪避", modifiers.evasion, "wind"),
                ("魔法", modifiers.magic, "sparkles")
            ].filter { $0.1 != 0 }

            if values.isEmpty {
                Text("无额外属性")
                    .font(.caption)
                    .foregroundStyle(RiftPalette.muted)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 7)], spacing: 7) {
                    ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                        HStack(spacing: 6) {
                            Image(systemName: value.2)
                                .foregroundStyle(RiftPalette.riftBlue)
                            Text(value.0)
                                .foregroundStyle(RiftPalette.muted)
                            Spacer()
                            Text(value.1 > 0 ? "+\(value.1)" : "\(value.1)")
                                .monospacedDigit()
                                .foregroundStyle(value.1 > 0 ? RiftPalette.success : RiftPalette.danger)
                        }
                        .font(.caption.weight(.bold))
                        .padding(8)
                        .background(RiftPalette.void.opacity(0.42), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        } else {
            Text(item.kind == .consumable ? "可在战斗中作为战术补给使用。" : "关键任务物品，无法装备或丢弃。")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RiftPalette.muted)
        }
    }

    private func skillCard(_ skill: CharacterSkillRow) -> some View {
        let tint = RiftSkillIconography.tint(for: skill.id)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(tint.opacity(0.13))
                    Image(systemName: RiftSkillIconography.icon(for: skill.id))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(tint)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.displayName)
                        .font(.headline.weight(.black))
                        .foregroundStyle(RiftPalette.frost)
                    Text("目标：\(skill.targetName)")
                        .font(.caption)
                        .foregroundStyle(RiftPalette.muted)
                }
                Spacer()
                RiftStatusPill(text: "\(skill.actionPointCost) AP", tint: RiftPalette.ember)
            }

            Text(skill.description)
                .font(.caption)
                .foregroundStyle(RiftPalette.muted)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Label("\(skill.range, format: .number.precision(.fractionLength(1))) 距离", systemImage: "ruler")
                Spacer()
                Text(skill.targetName)
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(RiftPalette.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [tint.opacity(0.10), RiftPalette.panelRaised], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(tint.opacity(0.38), lineWidth: 1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("技能 \(skill.displayName)，消耗 \(skill.actionPointCost) AP，距离 \(skill.range)，目标 \(skill.targetName)")
    }

    private func comparisonSummary(for item: ItemDefinition) -> String? {
        guard
            let actor = viewModel.selectedActor,
            let equipment = item.equipment,
            let currentID = actor.equipment.itemID(in: equipment.slot),
            currentID != item.id,
            let current = viewModel.itemDefinitions.first(where: { $0.id == currentID })
        else {
            return item.equipment == nil ? nil : "当前槽位为空，装备后将直接获得以上属性。"
        }
        return "将替换 \(current.displayName)。确认属性取舍后再装备。"
    }

    private func kindName(_ kind: ItemKind?) -> String {
        switch kind {
        case .equipment:
            "装备"
        case .consumable:
            "消耗品"
        case .quest:
            "任务物品"
        case nil:
            "未知"
        }
    }

    private func classLabel(_ classID: String?) -> String {
        switch classID {
        case "warrior": "守誓者"
        case "archer": "游猎者"
        case "mage": "研习者"
        case "rogue": "追猎者"
        default: "远征者"
        }
    }
}
