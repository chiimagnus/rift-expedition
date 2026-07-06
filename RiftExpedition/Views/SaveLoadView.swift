import RiftCore
import SwiftUI

struct SaveLoadView: View {
    let viewModel: SaveLoadViewModel
    let onClose: () -> Void

    var body: some View {
        RiftPanelScaffold(
            title: "存档",
            subtitle: "5 个手动槽，5 个自动槽；自动存档只允许安全点写入。",
            closeLabel: "返回",
            onClose: onClose,
            maxWidth: 1040
        ) {
            HStack(alignment: .top, spacing: 18) {
                slotColumn("手动存档", rows: viewModel.rows.filter { $0.slot.kind == .manual })
                slotColumn("自动存档", rows: viewModel.rows.filter { $0.slot.kind == .auto })
            }

            Text(viewModel.message)
                .font(.callout.weight(.semibold))
                .foregroundStyle(RiftPalette.bannerRed)
        }
    }

    private func slotColumn(_ title: String, rows: [SaveSlotRow]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(RiftPalette.textBrown)

            ForEach(rows) { row in
                slotRow(row)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RiftPalette.parchmentShade.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(RiftPalette.outline.opacity(0.4), lineWidth: 1.5)
                )
        )
    }

    private func slotRow(_ row: SaveSlotRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(RiftPalette.textBrown)
                Text(row.detail)
                    .font(.caption)
                    .foregroundStyle(row.isCorrupt ? RiftPalette.bannerRed : RiftPalette.textBrownLight)
            }

            Spacer()

            if row.slot.kind == .manual {
                Button("保存") {
                    viewModel.saveManual(slot: row.slot)
                }
                .buttonStyle(RiftSecondaryButtonStyle())
                .accessibilityLabel("保存到\(row.title)")
            }

            Button("读取") {
                viewModel.load(slot: row.slot)
            }
            .buttonStyle(RiftPrimaryButtonStyle())
            .disabled(!row.canLoad)
            .accessibilityLabel("读取\(row.title)")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RiftPalette.parchment)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(row.isCorrupt ? RiftPalette.bannerRed.opacity(0.6) : RiftPalette.outline.opacity(0.35), lineWidth: 1.5)
                )
        )
    }
}
