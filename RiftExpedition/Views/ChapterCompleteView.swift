import SwiftUI

struct ChapterCompleteView: View {
    let onReturnToMenu: () -> Void
    let onOpenSaveLoad: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("第一章完成")
                .font(.system(size: 54, weight: .black, design: .serif))
                .foregroundStyle(.white)

            Text("血债落地，裂隙未眠。")
                .font(.title2.bold())
                .foregroundStyle(Color(red: 0.88, green: 0.74, blue: 0.38))

            Text("沈砚洗清了外来法师的罪名，顾怀恩的私印成了全村都看见的证据。旧矿洞暂时安静下来，但裂隙幼体仍躲在石缝深处。")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.80))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                Button("读取 / 管理存档", action: onOpenSaveLoad)
                    .accessibilityLabel("读取或管理存档")
                Button("返回主菜单", action: onReturnToMenu)
                    .accessibilityLabel("返回主菜单")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: 760, alignment: .leading)
        .padding(44)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(red: 0.82, green: 0.66, blue: 0.30).opacity(0.48), lineWidth: 1)
        )
        .padding(48)
    }
}
