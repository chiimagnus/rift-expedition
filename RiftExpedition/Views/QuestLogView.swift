import RiftCore
import SwiftUI

struct QuestLogView: View {
    let entries: [QuestLogEntry]
    let onClose: () -> Void

    var body: some View {
        RiftPanelScaffold(
            title: "任务与调查档案",
            subtitle: "线索、目标与区域指引会随调查进展更新。",
            closeLabel: "返回探索",
            onClose: onClose,
            maxWidth: 920
        ) {
            if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 34, weight: .light))
                    Text("当前没有已接任务")
                        .font(.headline)
                    Text("与村民交谈或调查异常地点，新的线索会记录在这里。")
                        .font(.caption)
                }
                .foregroundStyle(RiftPalette.muted)
                .frame(maxWidth: .infinity, minHeight: 260)
            } else {
                let activeEntries = entries.filter { $0.status == .active }
                let completedEntries = entries.filter { $0.status == .completed }

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if !activeEntries.isEmpty {
                            sectionHeader("进行中的调查", count: activeEntries.count, tint: RiftPalette.ember, icon: "location.fill")
                            ForEach(activeEntries) { entry in
                                questCard(entry)
                            }
                        }
                        if !completedEntries.isEmpty {
                            sectionHeader("已归档", count: completedEntries.count, tint: RiftPalette.success, icon: "checkmark.seal.fill")
                            ForEach(completedEntries) { entry in
                                questCard(entry)
                            }
                        }
                    }
                    .padding(2)
                }
                .frame(minHeight: 380)
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int, tint: Color, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(RiftPalette.frost)
            RiftStatusPill(text: "\(count)", tint: tint)
            Spacer()
        }
    }

    private func questCard(_ entry: QuestLogEntry) -> some View {
        let completed = entry.status == .completed
        let tint = completed ? RiftPalette.success : (entry.isMainQuest ? RiftPalette.ember : RiftPalette.riftBlue)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.14))
                    Image(systemName: entry.isMainQuest ? "crown.fill" : "diamond.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(tint)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        RiftStatusPill(text: entry.isMainQuest ? "主线" : "支线", tint: tint)
                        RiftStatusPill(text: completed ? "已完成" : "进行中", tint: completed ? RiftPalette.success : RiftPalette.riftViolet)
                    }
                    Text(entry.title)
                        .font(.title3.weight(.black))
                        .foregroundStyle(RiftPalette.frost)
                    Text(entry.objective)
                        .font(.callout)
                        .foregroundStyle(RiftPalette.muted)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            if !completed {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .foregroundStyle(RiftPalette.riftBlue)
                    Text(entry.locationHint)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RiftPalette.frost)
                }
                .padding(10)
                .background(RiftPalette.riftBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }

            if !entry.objectives.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("调查步骤")
                        .font(.caption2.weight(.black))
                        .tracking(1)
                        .foregroundStyle(RiftPalette.muted)

                    ForEach(Array(entry.objectives.enumerated()), id: \.offset) { index, objective in
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(completed ? RiftPalette.success : (index == 0 ? tint : RiftPalette.raised))
                                Text("\(index + 1)")
                                    .font(.caption2.monospaced().weight(.black))
                                    .foregroundStyle(completed || index == 0 ? RiftPalette.void : RiftPalette.muted)
                            }
                            .frame(width: 23, height: 23)

                            Text(objective)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(completed ? RiftPalette.muted : RiftPalette.frost)
                                .strikethrough(completed, color: RiftPalette.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(LinearGradient(colors: [tint.opacity(0.09), RiftPalette.panelRaised], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(tint.opacity(0.38), lineWidth: 1.1))
        )
        .opacity(completed ? 0.78 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title)，\(completed ? "已完成" : "进行中")，目标：\(entry.objective)")
    }
}
