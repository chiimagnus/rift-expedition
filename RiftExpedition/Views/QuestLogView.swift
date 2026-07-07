import RiftCore
import SwiftUI

struct QuestLogView: View {
    let entries: [QuestLogEntry]
    let onClose: () -> Void

    var body: some View {
        RiftPanelScaffold(
            title: "任务日志",
            subtitle: "追踪当前接取与已完成的任务。",
            closeLabel: "返回",
            onClose: onClose
        ) {
            if entries.isEmpty {
                Text("当前没有已接任务。")
                    .foregroundStyle(RiftPalette.textBrownLight)
            } else {
                VStack(spacing: 12) {
                    ForEach(entries) { entry in
                        questCard(entry)
                    }
                }
            }
        }
    }

    private func questCard(_ entry: QuestLogEntry) -> some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(entry.status == .completed ? RiftPalette.accentGreen : RiftPalette.goldButton)
                .frame(width: 6)
                .padding(.vertical, 10)
                .padding(.leading, 8)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RiftPalette.textBrown)
                Text(entry.objective)
                    .font(.callout)
                    .foregroundStyle(RiftPalette.textBrownLight)

                Text(entry.status == .completed ? "已完成" : "进行中")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        entry.status == .completed ? RiftPalette.accentGreenDark : RiftPalette.goldButtonDark,
                        in: Capsule()
                    )
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(RiftPalette.parchmentShade)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(RiftPalette.outline, lineWidth: 2))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title)，\(entry.status == .completed ? "已完成" : "进行中")，目标：\(entry.objective)")
    }
}
