import AppKit
import RiftCore
import SwiftUI

// MARK: - Cinematic visual language

/// The canonical dark, high-contrast tactical fantasy palette.
/// Call sites use semantic color names so visual intent remains explicit.
enum RiftPalette {
    static let void = Color(red: 0.025, green: 0.035, blue: 0.055)
    static let obsidian = Color(red: 0.055, green: 0.075, blue: 0.105)
    static let raised = Color(red: 0.085, green: 0.11, blue: 0.15)
    static let steel = Color(red: 0.31, green: 0.39, blue: 0.48)
    static let frost = Color(red: 0.80, green: 0.90, blue: 0.96)
    static let muted = Color(red: 0.56, green: 0.64, blue: 0.71)
    static let riftBlue = Color(red: 0.20, green: 0.78, blue: 0.96)
    static let riftViolet = Color(red: 0.53, green: 0.31, blue: 0.94)
    static let ember = Color(red: 0.95, green: 0.58, blue: 0.19)
    static let danger = Color(red: 0.92, green: 0.25, blue: 0.30)
    static let success = Color(red: 0.26, green: 0.78, blue: 0.58)

    static let panel = Color(red: 0.075, green: 0.095, blue: 0.13)
    static let panelRaised = Color(red: 0.105, green: 0.13, blue: 0.17)
    static let border = Color(red: 0.33, green: 0.43, blue: 0.53)
    static let riftVioletDeep = Color(red: 0.31, green: 0.16, blue: 0.60)
    static let emberDeep = Color(red: 0.69, green: 0.34, blue: 0.10)
    static let successDeep = Color(red: 0.12, green: 0.56, blue: 0.43)
}

// MARK: - Atmospheric background

struct RiftWoodBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            GeometryReader { proxy in
                let size = proxy.size
                let time = timeline.date.timeIntervalSinceReferenceDate

                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.035, green: 0.06, blue: 0.09),
                            RiftPalette.void,
                            Color(red: 0.045, green: 0.025, blue: 0.075)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Ellipse()
                        .fill(RiftPalette.riftViolet.opacity(0.24))
                        .frame(width: size.width * 0.72, height: size.height * 0.30)
                        .blur(radius: 90)
                        .rotationEffect(.degrees(-18))
                        .offset(x: size.width * 0.20, y: -size.height * 0.18)

                    Ellipse()
                        .fill(RiftPalette.riftBlue.opacity(0.16))
                        .frame(width: size.width * 0.52, height: size.height * 0.20)
                        .blur(radius: 70)
                        .rotationEffect(.degrees(-18))
                        .offset(x: size.width * 0.13, y: -size.height * 0.15)

                    Canvas { context, canvasSize in
                        for index in 0..<42 {
                            let seed = Double(index * 97 % 41) / 41.0
                            let drift = (time * (0.008 + seed * 0.012)).truncatingRemainder(dividingBy: 1)
                            let x = canvasSize.width * CGFloat((seed * 1.73 + drift).truncatingRemainder(dividingBy: 1))
                            let ySeed = Double(index * 53 % 37) / 37.0
                            let y = canvasSize.height * CGFloat((ySeed + sin(time * 0.25 + Double(index)) * 0.025).truncatingRemainder(dividingBy: 1))
                            let radius = CGFloat(0.8 + seed * 1.8)
                            let rect = CGRect(x: x, y: y, width: radius, height: radius)
                            let color = index.isMultiple(of: 3) ? RiftPalette.riftBlue : RiftPalette.riftViolet
                            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.18 + seed * 0.28)))
                        }
                    }
                    .blendMode(.screen)

                    LinearGradient(
                        colors: [.black.opacity(0.05), .clear, .black.opacity(0.58)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    RadialGradient(
                        colors: [.clear, .black.opacity(0.70)],
                        center: .center,
                        startRadius: min(size.width, size.height) * 0.18,
                        endRadius: max(size.width, size.height) * 0.72
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Logo and titles

struct RiftLogoMark: View {
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .stroke(RiftPalette.steel.opacity(0.8), lineWidth: 1)
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [RiftPalette.riftBlue, RiftPalette.riftViolet, RiftPalette.riftBlue],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [size * 0.22, size * 0.10])
                )
                .rotationEffect(.degrees(-22))
            Capsule()
                .fill(LinearGradient(colors: [RiftPalette.riftBlue, RiftPalette.riftViolet], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.12, height: size * 0.68)
                .rotationEffect(.degrees(24))
                .shadow(color: RiftPalette.riftBlue.opacity(0.8), radius: 10)
            Capsule()
                .fill(.white.opacity(0.82))
                .frame(width: size * 0.035, height: size * 0.48)
                .rotationEffect(.degrees(24))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct RiftBannerTitle: View {
    let title: String

    var body: some View {
        HStack(spacing: 11) {
            RiftLogoMark(size: 31)
            Text(title.uppercased())
                .font(.system(size: 19, weight: .black, design: .rounded))
                .tracking(1.2)
        }
        .foregroundStyle(RiftPalette.frost)
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RiftPalette.obsidian.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [RiftPalette.riftBlue.opacity(0.8), RiftPalette.riftViolet.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: RiftPalette.riftViolet.opacity(0.28), radius: 18, y: 7)
    }
}

// MARK: - Panels

private struct RiftParchmentPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [RiftPalette.raised.opacity(0.96), RiftPalette.panel.opacity(0.98)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [RiftPalette.riftBlue.opacity(0.38), RiftPalette.border.opacity(0.45), RiftPalette.riftViolet.opacity(0.30)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(LinearGradient(colors: [.white.opacity(0.13), .clear], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 1)
                            .padding(.horizontal, cornerRadius)
                    }
                    .shadow(color: .black.opacity(0.62), radius: 28, y: 18)
            )
    }
}

extension View {
    func riftParchmentPanel(cornerRadius: CGFloat = 20) -> some View {
        modifier(RiftParchmentPanelModifier(cornerRadius: cornerRadius))
    }

    func riftHUDPanel(cornerRadius: CGFloat = 16) -> some View {
        padding(14)
            .background(.black.opacity(0.18))
            .riftParchmentPanel(cornerRadius: cornerRadius)
    }

    func riftHoverLift() -> some View {
        modifier(RiftHoverLiftModifier())
    }
}

private struct RiftHoverLiftModifier: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? 1.015 : 1)
            .offset(y: isHovering ? -2 : 0)
            .shadow(color: RiftPalette.riftBlue.opacity(isHovering ? 0.18 : 0), radius: 14, y: 8)
            .animation(.easeOut(duration: 0.16), value: isHovering)
            .onHover { isHovering = $0 }
    }
}

struct RiftPanelScaffold<Content: View>: View {
    let title: String
    var subtitle: String?
    var closeLabel: String = "返回"
    var onClose: (() -> Void)?
    var maxWidth: CGFloat = 760
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 14) {
                    RiftBannerTitle(title: title)

                    if let subtitle {
                        Text(subtitle)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(RiftPalette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer()
                    }

                    if let onClose {
                        Button(action: onClose) {
                            Label(closeLabel, systemImage: "xmark")
                        }
                        .buttonStyle(RiftGhostButtonStyle())
                        .keyboardShortcut(.cancelAction)
                        .accessibilityLabel(closeLabel)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .background(RiftPalette.void.opacity(0.48))

                Rectangle()
                    .fill(LinearGradient(colors: [RiftPalette.riftBlue.opacity(0.55), RiftPalette.riftViolet.opacity(0.45), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 18) {
                    content()
                }
                .padding(24)
            }
            .frame(maxWidth: maxWidth, alignment: .leading)
            .riftParchmentPanel(cornerRadius: 24)
            .padding(34)
        }
    }
}

struct RiftSectionHeader: View {
    let eyebrow: String?
    let title: String
    var systemImage: String? = nil

    init(_ title: String, eyebrow: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.eyebrow = eyebrow
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(RiftPalette.riftBlue)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.caption2.weight(.black))
                        .tracking(1.4)
                        .foregroundStyle(RiftPalette.riftBlue)
                }
                Text(title)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(RiftPalette.frost)
            }
            Spacer()
        }
    }
}

struct RiftStatusPill: View {
    let text: String
    var tint: Color = RiftPalette.riftBlue
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
            }
            Text(text)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.45), lineWidth: 1))
    }
}

struct RiftMetricBar: View {
    let value: Double
    var tint: Color = RiftPalette.riftBlue
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.black.opacity(0.45))
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.72), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * min(max(value, 0), 1))
                    .shadow(color: tint.opacity(0.45), radius: 5)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

struct RiftKeycap: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.monospaced().weight(.black))
            .foregroundStyle(RiftPalette.frost)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(RiftPalette.raised, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(RiftPalette.border.opacity(0.8), lineWidth: 1))
    }
}

// MARK: - Buttons

struct RiftPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(RiftPalette.void)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.74, blue: 0.30), RiftPalette.ember], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.28), lineWidth: 1))
            )
            .shadow(color: RiftPalette.ember.opacity(configuration.isPressed ? 0.12 : 0.34), radius: configuration.isPressed ? 4 : 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(isEnabled ? 1 : 0.38)
            .animation(.easeOut(duration: 0.11), value: configuration.isPressed)
    }
}

struct RiftSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(RiftPalette.frost)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(configuration.isPressed ? RiftPalette.raised : RiftPalette.panelRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(RiftPalette.border.opacity(configuration.isPressed ? 0.9 : 0.55), lineWidth: 1)
                    )
            )
            .opacity(isEnabled ? 1 : 0.36)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct RiftGhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(RiftPalette.muted)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? RiftPalette.raised : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(RiftPalette.border.opacity(0.35), lineWidth: 1))
            .opacity(isEnabled ? 1 : 0.35)
    }
}

struct RiftActionButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    var tint: Color = RiftPalette.riftBlue

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(isSelected ? .white : RiftPalette.frost)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minWidth: 74, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.24) : RiftPalette.panelRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? tint : RiftPalette.border.opacity(0.48), lineWidth: isSelected ? 1.8 : 1)
                    )
            )
            .shadow(color: isSelected ? tint.opacity(0.30) : .clear, radius: 10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.32)
    }
}

struct RiftTabButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(isSelected ? .white : RiftPalette.muted)
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? RiftPalette.riftViolet.opacity(0.30) : RiftPalette.panelRaised.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSelected ? RiftPalette.riftBlue.opacity(0.85) : RiftPalette.border.opacity(0.34), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

// MARK: - Equipment and item presentation

struct RiftEquipSlotView: View {
    let icon: String
    let label: String
    let itemName: String

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(RiftPalette.panelRaised)
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(RiftPalette.border.opacity(0.72), lineWidth: 1.2))
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(itemName == "未装备" ? RiftPalette.muted : RiftPalette.riftBlue)
            }
            .frame(width: 58, height: 58)

            Text(label.uppercased())
                .font(.caption2.weight(.black))
                .tracking(0.8)
                .foregroundStyle(RiftPalette.muted)

            Text(itemName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(itemName == "未装备" ? RiftPalette.muted : RiftPalette.frost)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 84)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)：\(itemName)")
    }
}

struct RiftItemGridSlot: View {
    var icon: String?
    var tint: Color = RiftPalette.success
    var quantity: Int = 0
    var isSelected: Bool = false
    var rarity: ItemRarity? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(icon == nil ? RiftPalette.panelRaised.opacity(0.35) : RiftPalette.panelRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? RiftPalette.riftBlue : rarityColor.opacity(icon == nil ? 0.25 : 0.78), lineWidth: isSelected ? 2.2 : 1.2)
                )

            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .shadow(color: tint.opacity(0.25), radius: 7)
            }

            if quantity > 1 {
                Text("\(quantity)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.72), in: Capsule())
                    .padding(4)
            }
        }
        .frame(width: 72, height: 72)
    }

    private var rarityColor: Color {
        RiftRarityStyle.color(for: rarity)
    }
}

enum RiftRarityStyle {
    static func color(for rarity: ItemRarity?) -> Color {
        switch rarity ?? .common {
        case .common:
            RiftPalette.steel
        case .uncommon:
            RiftPalette.success
        case .rare:
            RiftPalette.riftBlue
        case .epic:
            RiftPalette.riftViolet
        }
    }

    static func name(for rarity: ItemRarity?) -> String {
        switch rarity ?? .common {
        case .common:
            "普通"
        case .uncommon:
            "精良"
        case .rare:
            "稀有"
        case .epic:
            "史诗"
        }
    }
}

// MARK: - Character art

@MainActor
enum RiftActorArt {
    private static var cache: [String: NSImage] = [:]
    private static var illustrationCache: [String: NSImage] = [:]

    static func visualID(forClassID classID: String?) -> String {
        switch classID {
        case "archer":
            "actor_archer"
        case "mage":
            "actor_mage"
        case "rogue":
            "actor_rogue"
        default:
            "actor_warrior"
        }
    }

    static func portraitFrame(forClassID classID: String?) -> NSImage? {
        portraitFrame(forVisualID: visualID(forClassID: classID))
    }

    static func portraitFrame(forVisualID visualID: String) -> NSImage? {
        if let cached = cache[visualID] {
            return cached
        }
        if let dedicatedPortrait = portraitIllustration(forVisualID: visualID) {
            cache[visualID] = dedicatedPortrait
            return dedicatedPortrait
        }
        guard
            let url = Bundle.main.url(forResource: "\(visualID)_anim", withExtension: "png", subdirectory: "Assets/Characters"),
            let sheet = NSImage(contentsOf: url)
        else {
            return nil
        }

        let frameWidth = sheet.size.width / 12
        let frameHeight = sheet.size.height / 4
        guard frameWidth > 0, frameHeight > 0 else { return nil }

        let source = NSRect(x: 0, y: sheet.size.height - frameHeight, width: frameWidth, height: frameHeight)
        let frame = NSImage(size: NSSize(width: frameWidth, height: frameHeight))
        frame.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        sheet.draw(
            in: NSRect(x: 0, y: 0, width: frameWidth, height: frameHeight),
            from: source,
            operation: .copy,
            fraction: 1
        )
        frame.unlockFocus()

        cache[visualID] = frame
        return frame
    }

    static func illustration(named name: String) -> NSImage? {
        if let cached = illustrationCache[name] {
            return cached
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets/Illustrations"),
              let image = NSImage(contentsOf: url)
        else {
            return nil
        }
        illustrationCache[name] = image
        return image
    }

    private static func portraitIllustration(forVisualID visualID: String) -> NSImage? {
        guard let assetName = portraitAssetName(forVisualID: visualID),
              let image = illustration(named: assetName)
        else {
            return nil
        }
        return image
    }

    private static func portraitAssetName(forVisualID visualID: String) -> String? {
        switch visualID {
        case "actor_warrior":
            return "portrait_actor_warrior"
        case "actor_archer":
            return "portrait_actor_archer"
        case "actor_mage":
            return "portrait_actor_mage"
        case "actor_rogue":
            return "portrait_actor_rogue"
        default:
            return nil
        }
    }
}

struct RiftVisualPortrait: View {
    let visualID: String
    var size: CGFloat = 84
    var tint: Color = RiftPalette.riftBlue

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(LinearGradient(colors: [tint.opacity(0.25), RiftPalette.obsidian], startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                        .stroke(tint.opacity(0.72), lineWidth: 1.4)
                )

            if let portrait = RiftActorArt.portraitFrame(forVisualID: visualID) {
                Image(nsImage: portrait)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.05)
            } else {
                Image(systemName: "person.crop.square.fill")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: tint.opacity(0.25), radius: 12, y: 5)
        .accessibilityHidden(true)
    }
}

struct RiftActorPortrait: View {
    let classID: String?
    var size: CGFloat = 56
    var isActive: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [RiftClassIconography.tint(for: classID).opacity(0.28), RiftPalette.obsidian],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.20, style: .continuous)
                        .stroke(isActive ? RiftPalette.riftBlue : RiftPalette.border.opacity(0.75), lineWidth: isActive ? 2 : 1.2)
                )

            if let portrait = RiftActorArt.portraitFrame(forClassID: classID) {
                Image(nsImage: portrait)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.055)
            } else {
                Image(systemName: RiftClassIconography.icon(for: classID ?? ""))
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: isActive ? RiftPalette.riftBlue.opacity(0.32) : .black.opacity(0.3), radius: 9, y: 4)
        .accessibilityHidden(true)
    }
}

struct RiftIllustrationCard: View {
    let illustrationID: String
    var height: CGFloat = 210
    var overlayTint: Color = RiftPalette.riftBlue
    var cornerRadius: CGFloat = 16

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [overlayTint.opacity(0.18), RiftPalette.void.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let art = RiftActorArt.illustration(named: illustrationID) {
                Image(nsImage: art)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [Color.clear, RiftPalette.void.opacity(0.18), RiftPalette.void.opacity(0.68)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                RiftLogoMark(size: min(height * 0.52, 110))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(overlayTint.opacity(0.36), lineWidth: 1)
        )
        .shadow(color: overlayTint.opacity(0.22), radius: 18, y: 8)
    }
}

// MARK: - Dialogue

struct RiftDialogOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 11) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(RiftPalette.riftBlue)
            configuration.label
                .font(.callout.weight(.bold))
                .foregroundStyle(RiftPalette.frost)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(RiftPalette.muted)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(configuration.isPressed ? RiftPalette.riftViolet.opacity(0.20) : RiftPalette.panelRaised)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(RiftPalette.border.opacity(0.46), lineWidth: 1))
        )
        .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

// MARK: - Iconography

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
            "moon.stars.fill"
        default:
            "person.fill"
        }
    }

    static func tint(for classID: String?) -> Color {
        switch classID {
        case "warrior":
            Color(red: 0.90, green: 0.42, blue: 0.28)
        case "archer":
            RiftPalette.success
        case "mage":
            RiftPalette.riftBlue
        case "rogue":
            RiftPalette.riftViolet
        default:
            RiftPalette.muted
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
        if item.rarity == .epic { return RiftPalette.riftViolet }
        if item.rarity == .rare { return RiftPalette.riftBlue }
        if item.kind == .consumable { return RiftPalette.success }
        if item.kind == .quest { return RiftPalette.ember }
        return RiftRarityStyle.color(for: item.rarity)
    }
}

enum RiftSkillIconography {
    static func icon(for skillID: String) -> String {
        switch skillID {
        case "slash": "drop.triangle.fill"
        case "shield_bash": "shield.fill"
        case "rallying_guard": "cross.vial.fill"
        case "aimed_shot", "poacher_shot": "scope"
        case "hamstring_shot": "arrow.down.right.circle.fill"
        case "oil_arrow": "flame.circle.fill"
        case "spark": "flame.fill"
        case "water_orb": "drop.fill"
        case "mending_light", "minor_healing_draught": "cross.fill"
        case "backstab": "moon.stars.fill"
        case "throwing_knife": "paperplane.fill"
        case "venom_edge": "allergens.fill"
        default: "sparkles"
        }
    }

    static func tint(for skillID: String) -> Color {
        switch skillID {
        case "spark", "oil_arrow": RiftPalette.ember
        case "water_orb": RiftPalette.riftBlue
        case "mending_light", "rallying_guard", "minor_healing_draught": RiftPalette.success
        case "venom_edge": Color(red: 0.58, green: 0.82, blue: 0.24)
        case "backstab", "throwing_knife": RiftPalette.riftViolet
        default: RiftPalette.frost
        }
    }
}
