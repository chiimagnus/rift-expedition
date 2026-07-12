import RiftCore
import SwiftUI

struct SaveLoadView: View {
    let viewModel: SaveLoadViewModel
    let onClose: () -> Void
    @State private var overwriteSlot: SaveSlot?

    var body: some View {
        RiftPanelScaffold(
            title: "远征记录",
            subtitle: "手动记录用于关键决策前备份；自动记录只会在安全节点写入。",
            closeLabel: "返回",
            onClose: onClose,
            maxWidth: 1_080
        ) {
            HStack(spacing: 10) {
                RiftStatusPill(text: "5 个手动槽", tint: RiftPalette.riftBlue, icon: "square.and.arrow.down.fill")
                RiftStatusPill(text: "5 个自动槽", tint: RiftPalette.riftViolet, icon: "clock.arrow.circlepath")
                Spacer()
                RiftStatusPill(text: "本地存档", tint: RiftPalette.success, icon: "internaldrive.fill")
            }

            HStack(alignment: .top, spacing: 18) {
                slotColumn(
                    "手动记录",
                    eyebrow: "MANUAL ARCHIVE",
                    icon: "bookmark.fill",
                    tint: RiftPalette.riftBlue,
                    rows: viewModel.rows.filter { $0.slot.kind == .manual }
                )
                slotColumn(
                    "自动记录",
                    eyebrow: "SAFEPOINT ARCHIVE",
                    icon: "clock.fill",
                    tint: RiftPalette.riftViolet,
                    rows: viewModel.rows.filter { $0.slot.kind == .auto }
                )
            }

            HStack(spacing: 9) {
                Image(systemName: messageIcon)
                    .foregroundStyle(messageTint)
                Text(viewModel.message)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(RiftPalette.textBrown)
                Spacer()
            }
            .padding(11)
            .background(messageTint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(messageTint.opacity(0.25), lineWidth: 1))
        }
        .confirmationDialog(
            "覆盖这个手动存档？",
            isPresented: Binding(
                get: { overwriteSlot != nil },
                set: { if !$0 { overwriteSlot = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("确认覆盖", role: .destructive) {
                if let overwriteSlot {
                    viewModel.saveManual(slot: overwriteSlot)
                }
                overwriteSlot = nil
            }
            Button("取消", role: .cancel) {
                overwriteSlot = nil
            }
        } message: {
            Text("旧进度将不能恢复。")
        }
    }

    private func slotColumn(
        _ title: String,
        eyebrow: String,
        icon: String,
        tint: Color,
        rows: [SaveSlotRow]
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            RiftSectionHeader(title, eyebrow: eyebrow, systemImage: icon)

            ForEach(rows) { row in
                slotRow(row, tint: tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [tint.opacity(0.06), RiftPalette.parchmentShade.opacity(0.80)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(tint.opacity(0.26), lineWidth: 1))
        )
    }

    private func slotRow(_ row: SaveSlotRow, tint: Color) -> some View {
        let stateTint = row.isCorrupt ? RiftPalette.danger : (row.canLoad ? tint : RiftPalette.steel)

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(stateTint.opacity(0.13))
                Image(systemName: row.isCorrupt ? "exclamationmark.triangle.fill" : (row.canLoad ? "doc.text.fill" : "doc.badge.plus"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(stateTint)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(row.title)
                        .font(.callout.weight(.black))
                        .foregroundStyle(RiftPalette.textBrown)
                    if row.isCorrupt {
                        RiftStatusPill(text: "损坏", tint: RiftPalette.danger)
                    } else if row.canLoad {
                        RiftStatusPill(text: "可读取", tint: RiftPalette.success)
                    }
                }
                Text(row.detail)
                    .font(.caption)
                    .foregroundStyle(row.isCorrupt ? RiftPalette.danger : RiftPalette.textBrownLight)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if row.slot.kind == .manual {
                Button {
                    if row.canLoad {
                        overwriteSlot = row.slot
                    } else {
                        viewModel.saveManual(slot: row.slot)
                    }
                } label: {
                    Image(systemName: row.canLoad ? "arrow.triangle.2.circlepath" : "square.and.arrow.down.fill")
                }
                .buttonStyle(RiftGhostButtonStyle())
                .help(row.canLoad ? "覆盖存档" : "保存到此槽")
                .accessibilityLabel("保存到\(row.title)")
            }

            Button {
                viewModel.load(slot: row.slot)
            } label: {
                Image(systemName: "play.fill")
            }
            .buttonStyle(RiftActionButtonStyle(isSelected: row.canLoad, tint: tint))
            .disabled(!row.canLoad)
            .help("读取存档")
            .accessibilityLabel("读取\(row.title)")
        }
        .padding(11)
        .background(RiftPalette.void.opacity(0.38), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(stateTint.opacity(row.canLoad || row.isCorrupt ? 0.34 : 0.16), lineWidth: 1))
    }

    private var messageTint: Color {
        if viewModel.message.contains("失败") || viewModel.message.contains("损坏") || viewModel.message.contains("拒绝") {
            return RiftPalette.danger
        }
        if viewModel.message.contains("已") {
            return RiftPalette.success
        }
        return RiftPalette.riftBlue
    }

    private var messageIcon: String {
        if viewModel.message.contains("失败") || viewModel.message.contains("损坏") || viewModel.message.contains("拒绝") {
            return "exclamationmark.triangle.fill"
        }
        if viewModel.message.contains("已") {
            return "checkmark.seal.fill"
        }
        return "info.circle.fill"
    }
}
