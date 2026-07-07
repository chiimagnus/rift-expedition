import SwiftUI

struct ChapterCompleteView: View {
    let onReturnToMenu: () -> Void
    let onOpenSaveLoad: () -> Void

    var body: some View {
        RiftPanelScaffold(
            title: "第一章完成",
            maxWidth: 760
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text("血案落地，裂隙未眠。")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RiftPalette.bannerRed)

                Text("沈砚洗清了外来法师的罪名，顾怀恩的私印成了全村都看见的证据。旧矿洞暂时安静下来，但裂隙幼体仍躲在石缝深处。")
                    .font(.title3)
                    .foregroundStyle(RiftPalette.textBrown.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 14) {
                    Button("读取 / 管理存档", action: onOpenSaveLoad)
                        .buttonStyle(RiftSecondaryButtonStyle())
                        .accessibilityLabel("读取或管理存档")
                    Button("返回主菜单", action: onReturnToMenu)
                        .buttonStyle(RiftPrimaryButtonStyle())
                        .accessibilityLabel("返回主菜单")
                }
            }
        }
    }
}
