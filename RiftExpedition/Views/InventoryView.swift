import RiftCore
import SwiftUI

struct InventoryView: View {
    let viewModel: InventoryViewModel
    let onClose: () -> Void

    @State private var selectedItemID: String?

    private let gridColumns = [GridItem(.adaptive(minimum: 72, maximum: 72), spacing: 12)]

    var body: some View {
        RiftPanelScaffold(
            title: "背包与角色",
            subtitle: "队伍共享背包；职业不限制装备与后续成长。",
            closeLabel: "返回探索",
            onClose: onClose,
            maxWidth: 900
        ) {
            HStack(alignment: .top, spacing: 24) {
                partyPanel
                itemPanel
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
            }

            Spacer()

            Text("数量 \(row.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(RiftPalette.textBrownLight)

            Button("装备") {
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
}
