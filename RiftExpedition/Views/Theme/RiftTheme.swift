import RiftCore
import SwiftUI

// 统一的"手绘卡通奇幻风（圆润明快）"视觉主题：木纹背景 + 羊皮纸面板 + 旗帜标题牌 +
// 立体圆角按钮。所有面板类界面（设置/任务日志/角色选择/背包与角色等）都应通过这里的
// 组件搭建，不要在各个视图里各自定义颜色和面板样式。

// MARK: - 配色

enum RiftPalette {
    static let woodDark = Color(red: 0.20, green: 0.13, blue: 0.09)
    static let woodMid = Color(red: 0.42, green: 0.27, blue: 0.17)
    static let parchment = Color(red: 0.91, green: 0.82, blue: 0.67)
    static let parchmentShade = Color(red: 0.84, green: 0.74, blue: 0.58)
    static let outline = Color(red: 0.30, green: 0.19, blue: 0.10)
    static let bannerRed = Color(red: 0.59, green: 0.17, blue: 0.16)
    static let bannerRedDark = Color(red: 0.45, green: 0.11, blue: 0.11)
    static let goldButton = Color(red: 0.88, green: 0.59, blue: 0.24)
    static let goldButtonDark = Color(red: 0.72, green: 0.42, blue: 0.16)
    static let textBrown = Color(red: 0.27, green: 0.18, blue: 0.10)
    static let textBrownLight = Color(red: 0.47, green: 0.35, blue: 0.24)
    static let accentGreen = Color(red: 0.43, green: 0.66, blue: 0.35)
    static let accentGreenDark = Color(red: 0.35, green: 0.51, blue: 0.27)
}

// MARK: - 木纹背景

struct RiftWoodBackground: View {
    var body: some View {
        LinearGradient(
            colors: [RiftPalette.woodMid, RiftPalette.woodDark, Color(red: 0.14, green: 0.09, blue: 0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            LinearGradient(colors: [.white.opacity(0.05), .clear, .black.opacity(0.22)], startPoint: .top, endPoint: .bottom)
        )
        .ignoresSafeArea()
    }
}

// MARK: - 旗帜标题牌

private struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notch = min(16, rect.height * 0.32)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct RiftBannerTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(
                RibbonShape()
                    .fill(LinearGradient(colors: [RiftPalette.bannerRed, RiftPalette.bannerRedDark], startPoint: .top, endPoint: .bottom))
                    .overlay(RibbonShape().stroke(RiftPalette.outline, lineWidth: 2))
            )
            .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
            .fixedSize()
    }
}

// MARK: - 羊皮纸面板

private struct RiftParchmentPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = 26

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(RiftPalette.parchment)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(RiftPalette.outline, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
            )
    }
}

extension View {
    func riftParchmentPanel(cornerRadius: CGFloat = 26) -> some View {
        modifier(RiftParchmentPanelModifier(cornerRadius: cornerRadius))
    }
}

/// 面板骨架：旗帜标题牌叠在羊皮纸面板顶部，内容区自动预留标题牌遮挡的空间。
/// 设置 / 任务日志 / 角色选择 / 背包与角色等全屏面板都应该用这个骨架搭建，
/// 保持统一的视觉语言，不要各自再发明新的背景和标题样式。
struct RiftPanelScaffold<Content: View>: View {
    let title: String
    var subtitle: String?
    var closeLabel: String = "返回"
    var onClose: (() -> Void)?
    var maxWidth: CGFloat = 760
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 24)

                if let subtitle {
                    Text(subtitle)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(RiftPalette.textBrownLight)
                }

                content()

                if let onClose {
                    Button(closeLabel, action: onClose)
                        .buttonStyle(RiftPrimaryButtonStyle())
                        .accessibilityLabel(closeLabel)
                }
            }
            .padding(28)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .riftParchmentPanel()

            RiftBannerTitle(title: title)
                .offset(y: -22)
        }
        .padding(.top, 22)
        .padding(32)
    }
}

// MARK: - 按钮样式

struct RiftPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(RiftPalette.textBrown)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [RiftPalette.goldButton, RiftPalette.goldButtonDark], startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().stroke(RiftPalette.outline, lineWidth: 2))
            )
            .shadow(color: .black.opacity(0.3), radius: configuration.isPressed ? 1 : 4, y: configuration.isPressed ? 1 : 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabledAppearance(configuration))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func isEnabledAppearance(_ configuration: Configuration) -> Double {
        1
    }
}

struct RiftSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(RiftPalette.textBrown)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(RiftPalette.parchmentShade)
                    .overlay(Capsule().stroke(RiftPalette.outline.opacity(0.7), lineWidth: 1.5))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct RiftTabButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .white : RiftPalette.textBrown)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? RiftPalette.accentGreen : RiftPalette.parchmentShade)
                    .overlay(Capsule().stroke(isSelected ? RiftPalette.accentGreenDark : RiftPalette.outline.opacity(0.6), lineWidth: isSelected ? 2 : 1.5))
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// MARK: - 装备格 / 物品格

struct RiftEquipSlotView: View {
    let icon: String
    let label: String
    let itemName: String

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RiftPalette.parchmentShade)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(RiftPalette.outline, lineWidth: 2.5))
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(RiftPalette.textBrown)
            }
            .frame(width: 56, height: 56)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RiftPalette.textBrownLight)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)：\(itemName)")
    }
}

struct RiftItemGridSlot: View {
    var icon: String?
    var tint: Color = RiftPalette.accentGreen
    var quantity: Int = 0
    var isSelected: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(icon == nil ? RiftPalette.parchmentShade.opacity(0.55) : RiftPalette.parchmentShade)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? RiftPalette.bannerRed : RiftPalette.outline.opacity(icon == nil ? 0.35 : 1), lineWidth: isSelected ? 3 : 2)
                )

            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if quantity > 1 {
                Text("\(quantity)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(RiftPalette.textBrown, in: Capsule())
                    .padding(4)
            }
        }
        .frame(width: 72, height: 72)
    }
}

// MARK: - 人物剪影（角色面板用的简化"纸娃娃"站姿，不是最终精灵图）

struct RiftHumanoidSilhouette: View {
    var tint: Color = RiftPalette.accentGreen

    var body: some View {
        VStack(spacing: -4) {
            Circle()
                .fill(Color(red: 0.88, green: 0.73, blue: 0.58))
                .overlay(Circle().stroke(RiftPalette.outline, lineWidth: 2))
                .frame(width: 32, height: 32)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(RiftPalette.outline, lineWidth: 2))
                .frame(width: 54, height: 60)

            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(red: 0.35, green: 0.27, blue: 0.20))
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(RiftPalette.outline, lineWidth: 1.5))
                    .frame(width: 14, height: 40)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(red: 0.35, green: 0.27, blue: 0.20))
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(RiftPalette.outline, lineWidth: 1.5))
                    .frame(width: 14, height: 40)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - 对话选项按钮（全宽行式，用于对话框/剧情选择列表）

struct RiftDialogOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "chevron.right")
                .font(.callout.weight(.bold))
                .foregroundStyle(RiftPalette.bannerRed)
            configuration.label
                .font(.callout.weight(.semibold))
                .foregroundStyle(RiftPalette.textBrown)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RiftPalette.parchmentShade)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(RiftPalette.outline.opacity(0.6), lineWidth: 1.5))
        )
        .opacity(configuration.isPressed ? 0.75 : 1)
        .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

// MARK: - 图标映射（职业 / 装备槽 / 物品）

enum RiftClassIconography {
    static func icon(for classID: String) -> String {
        switch classID {
        case "warrior":
            "shield.lefthalf.filled"
        case "archer":
            "scope"
        case "mage":
            "wand.and.stars"
        case "rogue":
            "scissors"
        default:
            "person.fill"
        }
    }

    static func tint(for classID: String?) -> Color {
        switch classID {
        case "warrior":
            Color(red: 0.72, green: 0.35, blue: 0.28)
        case "archer":
            RiftPalette.accentGreen
        case "mage":
            Color(red: 0.35, green: 0.51, blue: 0.75)
        case "rogue":
            Color(red: 0.55, green: 0.35, blue: 0.60)
        default:
            RiftPalette.textBrownLight
        }
    }
}

enum RiftEquipmentIconography {
    static func icon(for slot: EquipmentSlot) -> String {
        switch slot {
        case .weapon:
            "bolt.fill"
        case .armor:
            "shield.fill"
        case .accessory:
            "sparkles"
        }
    }
}

enum RiftItemIconography {
    static func icon(for item: ItemDefinition) -> String {
        if let equipment = item.equipment {
            return RiftEquipmentIconography.icon(for: equipment.slot)
        }
        switch item.kind {
        case .consumable:
            return "cross.case.fill"
        case .quest:
            return "scroll.fill"
        case .equipment:
            return "shippingbox.fill"
        }
    }

    static func tint(for item: ItemDefinition) -> Color {
        let palette: [Color] = [
            Color(red: 0.62, green: 0.42, blue: 0.30),
            Color(red: 0.35, green: 0.51, blue: 0.75),
            Color(red: 0.62, green: 0.55, blue: 0.24),
            Color(red: 0.72, green: 0.35, blue: 0.28),
            Color(red: 0.88, green: 0.59, blue: 0.24),
            RiftPalette.accentGreen
        ]
        let index = abs(item.id.hashValue) % palette.count
        return palette[index]
    }
}
