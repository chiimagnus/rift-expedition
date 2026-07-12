import SwiftUI

struct ChapterCompleteView: View {
    let onReturnToMenu: () -> Void
    let onOpenSaveLoad: () -> Void

    var body: some View {
        ZStack {
            RiftWoodBackground()

            HStack(spacing: 34) {
                VStack(alignment: .leading, spacing: 18) {
                    RiftStatusPill(text: "第一章完成", tint: RiftPalette.success, icon: "checkmark.seal.fill")

                    Text("血案落地，\n裂隙未眠。")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(RiftPalette.frost)
                        .lineSpacing(-2)

                    Text("沈砚洗清了外来法师的罪名，顾怀恩的私印成为全村都看见的证据。旧矿洞暂时安静下来，但封层深处的幼体仍在呼吸。")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(RiftPalette.textBrownLight)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 560, alignment: .leading)

                    HStack(spacing: 9) {
                        RiftStatusPill(text: "真相公开", tint: RiftPalette.riftBlue)
                        RiftStatusPill(text: "矿洞封锁", tint: RiftPalette.ember)
                        RiftStatusPill(text: "裂隙幼体存活", tint: RiftPalette.riftViolet)
                    }

                    HStack(spacing: 12) {
                        Button {
                            onOpenSaveLoad()
                        } label: {
                            Label("管理远征记录", systemImage: "square.and.arrow.down.fill")
                        }
                        .buttonStyle(RiftSecondaryButtonStyle())
                        .accessibilityLabel("读取或管理存档")

                        Button {
                            onReturnToMenu()
                        } label: {
                            Label("返回主菜单", systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(RiftPrimaryButtonStyle())
                        .keyboardShortcut(.defaultAction)
                        .accessibilityLabel("返回主菜单")
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 17) {
                    RiftIllustrationCard(
                        illustrationID: "chapter1_cave_depths",
                        height: 176,
                        overlayTint: RiftPalette.riftViolet,
                        cornerRadius: 18
                    )
                    Text("RIFT REMAINS")
                        .font(.caption.weight(.black))
                        .tracking(3)
                        .foregroundStyle(RiftPalette.riftBlue)

                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, RiftPalette.riftBlue.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 1)

                    epilogueRow(icon: "person.fill.checkmark", title: "沈砚", detail: "获救并成为矿洞真相的证人", tint: RiftPalette.success)
                    epilogueRow(icon: "building.columns.fill", title: "裂隙村", detail: "秩序开始重建，信任尚未恢复", tint: RiftPalette.ember)
                    epilogueRow(icon: "paintpalette.fill", title: "内容升级", detail: "本章已接入原创角色立绘、环境关键画与分层音景。", tint: RiftPalette.riftBlue)
                    epilogueRow(icon: "waveform.path.ecg", title: "封层回声", detail: "新的频率正在更深处回应", tint: RiftPalette.riftViolet)
                }
                .padding(24)
                .frame(width: 360)
                .riftParchmentPanel(cornerRadius: 22)
            }
            .padding(.horizontal, 72)
            .padding(.vertical, 56)
        }
    }

    private func epilogueRow(icon: String, title: String, detail: String, tint: Color) -> some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.13))
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.black))
                    .foregroundStyle(RiftPalette.textBrown)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(RiftPalette.textBrownLight)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}
