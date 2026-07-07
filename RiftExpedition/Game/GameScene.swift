import AppKit
import RiftCore
import SKTiled
import SpriteKit

@MainActor
protocol GameSceneEventHandling: AnyObject {
    func gameSceneDidLoad(_ scene: GameScene)
    func gameScene(_ scene: GameScene, didClickWorld point: CGPoint)
    func gameSceneDidRequestLeaderSwitch(_ scene: GameScene)
    func gameSceneDidRequestDebugToggle(_ scene: GameScene)
    func gameScene(_ scene: GameScene, didAdvance deltaTime: TimeInterval)
}

@MainActor
final class GameScene: SKScene {
    static let sceneSize = CGSize(width: 1280, height: 720)

    weak var eventHandler: (any GameSceneEventHandling)?
    var isWorldInputEnabled = true
    var assetBundle: Bundle = .main
    private let worldLayer = SKNode()
    private var tilemap: SKTilemap?
    private var loadedAreaID: String?
    private var lastUpdateTime: TimeInterval?
    private var partyNodes: [String: SKShapeNode] = [:]
    private var staticObjectLayer: SKNode?
    private var battleLayer: SKNode?
    private var textureCache: [String: SKTexture] = [:]
    private var animationFrameCache: [String: [SKTexture]] = [:]
    private lazy var actorAnimationCatalog: ActorAnimationCatalog? = ActorAnimationCatalog.load(bundle: assetBundle)
    private var didLogAnimationCatalogFallback = false

    static func makeScene() -> GameScene {
        let scene = GameScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        return scene
    }

    override func didMove(to view: SKView) {
        view.window?.makeFirstResponder(view)
        backgroundColor = SKColor(red: 0.08, green: 0.10, blue: 0.08, alpha: 1)
        preloadAnimationCatalogIfNeeded()
        if worldLayer.parent == nil {
            worldLayer.name = "worldLayer"
            worldLayer.zPosition = 0
            addChild(worldLayer)
        }
        drawGround()
        layoutWorld()
        eventHandler?.gameSceneDidLoad(self)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        drawGround()
        layoutWorld()
    }

    override func mouseDown(with event: NSEvent) {
        guard isWorldInputEnabled else { return }

        let scenePoint = event.location(in: self)
        let point = worldLayer.convert(scenePoint, from: self)
        eventHandler?.gameScene(self, didClickWorld: point)
        markClick(at: point)
    }

    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers?.lowercased() == "d" {
            eventHandler?.gameSceneDidRequestDebugToggle(self)
            return
        }

        guard isWorldInputEnabled else {
            super.keyDown(with: event)
            return
        }

        if event.charactersIgnoringModifiers == "\t" {
            eventHandler?.gameSceneDidRequestLeaderSwitch(self)
            return
        }
        super.keyDown(with: event)
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard let lastUpdateTime else { return }

        let deltaTime = min(currentTime - lastUpdateTime, 1.0 / 15.0)
        eventHandler?.gameScene(self, didAdvance: deltaTime)
    }

    func renderParty(_ members: [PartyMemberPosition], leaderID: String?) {
        let memberIDs = Set(members.map(\.actorID))
        let staleActorIDs = partyNodes.keys.filter { !memberIDs.contains($0) }
        for actorID in staleActorIDs {
            partyNodes[actorID]?.removeFromParent()
            partyNodes[actorID] = nil
        }

        for member in members {
            let node = partyNodes[member.actorID] ?? makePartyNode(for: member)
            node.position = member.position
            node.fillColor = member.actorID == leaderID
                ? SKColor(red: 0.88, green: 0.68, blue: 0.24, alpha: 1)
                : SKColor(red: 0.38, green: 0.72, blue: 0.78, alpha: 1)
            if let sprite = node.childNode(withName: "partySprite_\(member.actorID)") as? SKSpriteNode {
                sprite.xScale = member.facing == .left ? -abs(sprite.xScale) : abs(sprite.xScale)
                let isMoving = member.target != nil
                if isMoving {
                    if sprite.action(forKey: "walkBob") == nil {
                        sprite.run(.repeatForever(walkBobAction()), withKey: "walkBob")
                    }
                } else if sprite.action(forKey: "walkBob") != nil {
                    sprite.removeAction(forKey: "walkBob")
                    sprite.position = .zero
                }
            }
            partyNodes[member.actorID] = node
        }
    }

    /// 简单的“走路弹跳”动画：贴图相对自己原点小幅上下移动，配合 `renderParty` 里的
    /// 移动状态判断循环播放。做法参考了 `makeEffectNode` 里命中特效用到的 `SKAction` 序列。
    private func walkBobAction() -> SKAction {
        let up = SKAction.moveBy(x: 0, y: 3, duration: 0.15)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        return .sequence([up, down])
    }

    func renderBattle(_ snapshot: BattleSceneSnapshot?) {
        battleLayer?.removeFromParent()
        battleLayer = nil
        guard let snapshot else { return }

        let layer = SKNode()
        layer.name = "battleLayer"
        // 这里把数值调得比 SKTiled 内部图层可能用到的 zPosition 都高很多
        // （具体原因见下面 staticObjectLayer / 队伍节点相关的注释）。
        layer.zPosition = 700
        worldLayer.addChild(layer)
        battleLayer = layer

        // ponytail（有意为之的技术债）：目前战斗里角色很少，每次整体重建这层显示内容
        // 比费劲做「按 key 找差异只更新变化部分」更简单清楚。
        for surface in snapshot.surfaces {
            layer.addChild(makeSurfaceNode(surface))
        }
        if let activeActor = snapshot.actors.first(where: { $0.id == snapshot.activeActorID }) {
            layer.addChild(makeMoveRangeNode(center: activeActor.position, radius: snapshot.moveRadius))
        }
        for actor in snapshot.actors {
            layer.addChild(makeBattleActorNode(actor))
        }
        if let point = snapshot.lastEffectPoint {
            layer.addChild(makeEffectNode(at: point))
        }
    }

    func loadMap(areaID: String) {
        guard loadedAreaID != areaID else { return }

        tilemap?.removeFromParent()
        tilemap = nil
        staticObjectLayer?.removeFromParent()
        staticObjectLayer = nil

        do {
            let (loadedMap, metadata) = try TiledMapLoader.load(areaID: areaID)
            loadedMap.position = .zero
            loadedMap.zPosition = 1
            worldLayer.addChild(loadedMap)
            tilemap = loadedMap
            loadedAreaID = areaID
            renderStaticObjects(metadata: metadata)
            layoutWorld()
        } catch {
            loadedAreaID = nil
            layoutWorld()
            GameLog.map.error("\(areaID, privacy: .public).tmx 加载失败")
        }
    }

    private func drawGround() {
        childNode(withName: "ground")?.removeFromParent()

        let ground = SKShapeNode(rectOf: size)
        ground.name = "ground"
        ground.fillColor = SKColor(red: 0.14, green: 0.19, blue: 0.12, alpha: 1)
        ground.strokeColor = SKColor(red: 0.38, green: 0.32, blue: 0.20, alpha: 1)
        ground.lineWidth = 6
        ground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        ground.zPosition = -100
        addChild(ground)
    }

    private func layoutWorld() {
        // tilemap 在 worldLayer 里的坐标是 (0, 0)，所以 tilemap.boundingRect 用的
        // 已经是 worldLayer 自己的坐标系。这里用地图的「实际中心点」来居中，
        // 而不是假设左下角是 (0, 0)，因为 SKTiled 默认的 `.center` 对齐方式是
        // 以地图自己的原点为中心铺开，而不是以左下角为准。
        guard let tilemap else {
            worldLayer.setScale(1)
            worldLayer.position = .zero
            return
        }

        let mapRect = tilemap.boundingRect
        let mapWidth = abs(mapRect.width)
        let mapHeight = abs(mapRect.height)
        guard mapWidth > 0, mapHeight > 0 else {
            worldLayer.setScale(1)
            worldLayer.position = .zero
            return
        }

        let fitScale = min(size.width / mapWidth, size.height / mapHeight) * 0.94
        let scale = min(max(fitScale, 0.35), 2.0)
        worldLayer.setScale(scale)
        worldLayer.position = CGPoint(
            x: size.width / 2 - mapRect.midX * scale,
            y: size.height / 2 - mapRect.midY * scale
        )
    }

    private func markClick(at point: CGPoint) {
        worldLayer.childNode(withName: "clickMarker")?.removeFromParent()

        let marker = SKShapeNode(circleOfRadius: 10)
        marker.name = "clickMarker"
        marker.position = point
        marker.fillColor = SKColor(red: 0.86, green: 0.73, blue: 0.34, alpha: 0.85)
        marker.strokeColor = .white
        marker.lineWidth = 2
        marker.zPosition = 560
        worldLayer.addChild(marker)
    }

    private func makePartyNode(for member: PartyMemberPosition) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 14)
        node.name = "party_\(member.actorID)"
        node.strokeColor = .white
        node.lineWidth = 2
        // 参考 renderStaticObjects 里 staticObjectLayer.zPosition 的注释：这里把数值从
        // 10 调高了不少，确保队伍标记不会被地图图层挡住。
        node.zPosition = 550
        worldLayer.addChild(node)

        let sprite = SKSpriteNode(texture: texture(named: partySpriteName(for: member)))
        sprite.name = "partySprite_\(member.actorID)"
        sprite.size = CGSize(width: 30, height: 30)
        sprite.zPosition = 1
        node.addChild(sprite)

        return node
    }

    private func partySpriteName(for member: PartyMemberPosition) -> String {
        guard let classID = member.classID else { return staticTextureName(for: "actor_warrior") }
        return staticTextureName(for: "actor_\(classID)")
    }

    private func renderStaticObjects(metadata: TiledMapMetadata) {
        staticObjectLayer?.removeFromParent()
        let layer = SKNode()
        layer.name = "staticObjectLayer"
        // SKTiled 的 `SKTilemap` 会给它从 .tmx 文件里解析出来的每个图层自己分配一个内部
        // zPosition，按文件里出现的顺序往上叠。这套机制 SKTiled 官方没有公开说明、属于它内部
        // 实现细节，所以与其猜一个「应该够用」的数值，这里干脆调得比它内部可能用到的任何数值
        // 都高很多，确保 staticObjectLayer（以及同级的队伍标记、点击标记、战斗层）
        // 不会被地图瓦片挡住。同时配合 GameRootView 里 SpriteView 的 `ignoresSiblingOrder`
        // 开关，让 zPosition 变成全局排序，而不是一层层按父子关系排。
        layer.zPosition = 500
        worldLayer.addChild(layer)
        staticObjectLayer = layer

        for surface in metadata.surfaces {
            guard let type = SurfaceTypeColor(rawValue: surface.surfaceType) else { continue }
            layer.addChild(makeStaticSurfaceNode(frame: surface.frame, color: type.color))
        }
        for obstacle in metadata.navObstacles where obstacle.blocksMovement {
            if let node = makeVisibleObstacleNode(obstacle) {
                layer.addChild(node)
            }
        }
        for exit in metadata.exits {
            layer.addChild(makeExitMarker(exit))
        }
        for trigger in metadata.triggers {
            layer.addChild(makeTriggerMarker(trigger))
        }
        // 遭遇触发区（伏击点）必须始终显示，没有例外。这个项目的设计里没有「隐藏伏击」这种
        // 玩法（所有遭遇战都是地图上固定安排好的，不是随机出现的——见 Docs/chapter1-worldgraph.md），
        // 所以如果触发区完全看不见，那是渲染上的 bug，不是故意藏起来防剧透。
        for encounter in metadata.encounterTriggers {
            layer.addChild(makeEncounterMarker(encounter))
        }
        for npc in metadata.npcs {
            layer.addChild(makeMapSprite(name: spriteName(forNPC: npc), position: npc.position, size: CGSize(width: 52, height: 52)))
        }
        for item in metadata.items {
            layer.addChild(makeMapSprite(name: spriteName(forMapItem: item), position: item.position, size: CGSize(width: 48, height: 48)))
        }
    }

    private func makeBattleActorNode(_ actor: BattleActorMarker) -> SKNode {
        let container = SKNode()
        container.name = "battleActor_\(actor.id)"
        container.position = actor.position
        container.alpha = actor.isDefeated ? 0.42 : 1

        let ring = SKShapeNode(circleOfRadius: actor.isActive ? 34 : 30)
        ring.fillColor = actor.isActive
            ? SKColor(red: 0.84, green: 0.73, blue: 0.42, alpha: 0.20)
            : SKColor.black.withAlphaComponent(0.28)
        ring.strokeColor = actor.isTargetable
            ? SKColor(red: 0.92, green: 0.24, blue: 0.18, alpha: 1)
            : actor.isActive ? SKColor(red: 0.84, green: 0.73, blue: 0.42, alpha: 1) : .white.withAlphaComponent(0.35)
        ring.lineWidth = actor.isTargetable || actor.isActive ? 4 : 2
        ring.zPosition = -1
        container.addChild(ring)

        let sprite = SKSpriteNode(texture: texture(named: actor.spriteName))
        sprite.size = CGSize(width: 58, height: 58)
        sprite.zPosition = 1
        container.addChild(sprite)

        let healthBack = SKShapeNode(rectOf: CGSize(width: 52, height: 6), cornerRadius: 3)
        healthBack.position = CGPoint(x: 0, y: -40)
        healthBack.fillColor = SKColor.black.withAlphaComponent(0.65)
        healthBack.strokeColor = .clear
        container.addChild(healthBack)

        let healthRatio = CGFloat(max(0, actor.health)) / CGFloat(max(actor.maxHealth, 1))
        let health = SKShapeNode(rect: CGRect(x: -26, y: -43, width: 52 * healthRatio, height: 6), cornerRadius: 3)
        health.fillColor = SKColor(red: 0.76, green: 0.18, blue: 0.16, alpha: 1)
        health.strokeColor = .clear
        container.addChild(health)

        let label = SKLabelNode(text: actor.displayName)
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 12
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 42)
        label.verticalAlignmentMode = .center
        container.addChild(label)
        return container
    }

    private func makeMoveRangeNode(center: CGPoint, radius: CGFloat) -> SKNode {
        let node = SKShapeNode(circleOfRadius: max(0, radius))
        node.name = "moveRange"
        node.position = center
        node.fillColor = SKColor(red: 0.25, green: 0.72, blue: 0.52, alpha: 0.08)
        node.strokeColor = SKColor(red: 0.42, green: 0.95, blue: 0.64, alpha: 0.42)
        node.lineWidth = 2
        node.zPosition = -4
        return node
    }

    private func makeEffectNode(at point: CGPoint) -> SKNode {
        let node = SKShapeNode(circleOfRadius: 18)
        node.name = "battleEffect"
        node.position = point
        node.fillColor = SKColor(red: 1.0, green: 0.46, blue: 0.14, alpha: 0.42)
        node.strokeColor = SKColor(red: 1.0, green: 0.86, blue: 0.38, alpha: 0.9)
        node.lineWidth = 3
        node.run(.sequence([
            .group([
                .scale(to: 2.0, duration: 0.18),
                .fadeOut(withDuration: 0.18)
            ]),
            .removeFromParent()
        ]))
        return node
    }

    private func makeSurfaceNode(_ surface: BattleSurfaceMarker) -> SKNode {
        makeStaticSurfaceNode(frame: surface.frame, color: SurfaceTypeColor(surface.surfaceType).color)
    }

    private func makeStaticSurfaceNode(frame: CGRect, color: SKColor) -> SKNode {
        let node = SKShapeNode(rect: frame, cornerRadius: 8)
        node.fillColor = color.withAlphaComponent(0.42)
        node.strokeColor = color.withAlphaComponent(0.82)
        node.lineWidth = 2
        node.zPosition = -5
        return node
    }

    private func makeVisibleObstacleNode(_ obstacle: NavigationObstacle) -> SKNode? {
        guard shouldRenderAsProp(obstacle) else { return nil }

        // ponytail（有意为之的技术债）：目前只画好了 prop_chest（箱子）/prop_woodpile（木堆）
        // 两张图，所以像水井、碎石堆、矿堆、残墙之类的独立障碍物暂时都先借用同一张占位贴图。
        // 等以后 assets-manifest.json 里给每种障碍物都登记了专属美术资源，再回来换掉。
        let sprite = SKSpriteNode(texture: texture(named: "prop_woodpile"))
        sprite.name = "obstacleProp_\(obstacle.tiledID)"
        sprite.size = CGSize(width: max(obstacle.frame.width, 42), height: max(obstacle.frame.height, 42))
        sprite.position = CGPoint(x: obstacle.frame.midX, y: obstacle.frame.midY)
        return sprite
    }

    // 这是第一章所有 .tmx 地图里出现过的真实障碍物名字（搜索所有 navObstacle 对象组得到），
    // 不包含每张地图都有的四面边界墙（北/南/西/东边界/村墙/浅河边界/河岸护栏）——
    // 这些边界墙的尺寸总是比任何装饰性障碍物大得多，不管在不在这个名单里，
    // 都会被下面的尺寸判断规则排除掉。
    private static let obstaclePropNameFragments = [
        "倒木", "木料", "篱笆", "货车", "废木堆",
        "石井", "旧告示墙", "裂隙核心", "塌陷石带", "坍塌矿架",
        "毒雾裂缝", "矿车轨道断口", "元素矿堆", "断塔石影", "塌墙", "旧炉台"
    ]

    private func shouldRenderAsProp(_ obstacle: NavigationObstacle) -> Bool {
        // 尺寸上限从 192x96 调大了，这样比较高/比较宽的真实障碍物（比如坍塌矿架 128x192、
        // 裂隙核心 160x160）也能算进来；同时又远小于每张地图边界墙的尺寸（边界墙至少有一边
        // 大于等于 480），所以边界墙无论如何都还是会被排除掉。
        guard obstacle.frame.width <= 280, obstacle.frame.height <= 220 else { return false }
        guard let name = obstacle.name else { return false }
        return Self.obstaclePropNameFragments.contains { name.localizedStandardContains($0) }
    }

    private func makeExitMarker(_ exit: MapExit) -> SKNode {
        let node = SKNode()
        node.name = "exitMarker_\(exit.tiledID)"
        node.position = CGPoint(x: exit.frame.midX, y: exit.frame.midY)
        node.zPosition = 8

        let plate = SKShapeNode(rectOf: CGSize(width: max(exit.frame.width + 28, 72), height: max(exit.frame.height + 20, 64)), cornerRadius: 12)
        plate.fillColor = SKColor(red: 0.93, green: 0.62, blue: 0.18, alpha: 0.20)
        plate.strokeColor = SKColor(red: 0.97, green: 0.75, blue: 0.30, alpha: 0.92)
        plate.lineWidth = 3
        node.addChild(plate)

        let arrow = SKLabelNode(text: arrowText(for: exit.frame))
        arrow.fontName = "PingFangSC-Semibold"
        arrow.fontSize = 22
        arrow.fontColor = SKColor(red: 1.0, green: 0.86, blue: 0.42, alpha: 1)
        arrow.verticalAlignmentMode = .center
        arrow.position = CGPoint(x: 0, y: 13)
        node.addChild(arrow)

        let label = SKLabelNode(text: exit.name ?? "出口")
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 12
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -15)
        node.addChild(label)
        return node
    }

    private func makeTriggerMarker(_ trigger: MapTrigger) -> SKNode {
        let node = SKNode()
        node.name = "triggerMarker_\(trigger.tiledID)"
        node.position = CGPoint(x: trigger.frame.midX, y: trigger.frame.midY)
        node.zPosition = 7

        let pin = SKShapeNode(circleOfRadius: 12)
        pin.fillColor = SKColor(red: 0.38, green: 0.72, blue: 0.78, alpha: 0.72)
        pin.strokeColor = .white
        pin.lineWidth = 2
        node.addChild(pin)

        let label = SKLabelNode(text: trigger.name ?? "线索")
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 11
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -24)
        node.addChild(label)
        return node
    }

    private func makeEncounterMarker(_ encounter: MapEncounterTrigger) -> SKNode {
        // 始终可见——这个项目没有隐藏伏击的设计，所以遭遇区域要和出口、剧情触发点一样清楚地
        // 显示出来，不能等玩家走进去才突然出现。
        let node = SKNode()
        node.name = "encounterMarker_\(encounter.tiledID)"
        node.position = encounter.center
        node.zPosition = 7

        let pin = SKShapeNode(circleOfRadius: 14)
        pin.fillColor = SKColor(red: 0.82, green: 0.20, blue: 0.16, alpha: 0.78)
        pin.strokeColor = .white
        pin.lineWidth = 2
        node.addChild(pin)

        let glyph = SKLabelNode(text: "⚔")
        glyph.fontSize = 14
        glyph.verticalAlignmentMode = .center
        node.addChild(glyph)

        return node
    }

    private func arrowText(for frame: CGRect) -> String {
        guard let tilemap else { return "→" }
        let mapRect = tilemap.boundingRect
        let mapWidth = mapRect.maxX - mapRect.minX
        let mapHeight = mapRect.maxY - mapRect.minY
        if frame.midX <= mapRect.minX + mapWidth * 0.2 { return "←" }
        if frame.midX >= mapRect.maxX - mapWidth * 0.2 { return "→" }
        if frame.midY <= mapRect.minY + mapHeight * 0.2 { return "↑" }
        if frame.midY >= mapRect.maxY - mapHeight * 0.2 { return "↓" }
        return "→"
    }

    private func makeMapSprite(name: String, position: CGPoint, size: CGSize) -> SKNode {
        let sprite = SKSpriteNode(texture: texture(named: name))
        sprite.name = name
        sprite.position = position
        sprite.size = size
        return sprite
    }

    private func texture(named name: String) -> SKTexture? {
        if let texture = textureCache[name] {
            return texture
        }
        if let texture = villageNPCTexture(named: name)
            ?? humanEnemyTexture(named: name)
            ?? beastMonsterTexture(named: name) {
            textureCache[name] = texture
            return texture
        }
        let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets/Sprites")
            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets/Characters")
            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets/Icons")
        guard let url, let image = NSImage(contentsOf: url) else {
            return nil
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        textureCache[name] = texture
        return texture
    }

    private func preloadAnimationCatalogIfNeeded() {
        guard actorAnimationCatalog == nil, !didLogAnimationCatalogFallback else { return }
        didLogAnimationCatalogFallback = true
        GameLog.assets.notice("Actor animation catalog unavailable; using static texture fallback")
    }

    private func animationFrames(
        visualID: String,
        action: ActorAnimationKind,
        direction: ActorAnimationDirection
    ) -> [SKTexture]? {
        let cacheKey = "\(visualID)/\(action.rawValue)/\(direction.rawValue)"
        if let frames = animationFrameCache[cacheKey] {
            return frames
        }
        guard
            let catalog = actorAnimationCatalog,
            let sheetPath = catalog.sheetPath(for: visualID),
            let sheetTexture = texture(sheetPath: sheetPath)
        else {
            return nil
        }

        let frames = catalog.frames(for: visualID, action: action, direction: direction).map { rect in
            let texture = SKTexture(rect: rect, in: sheetTexture)
            texture.filteringMode = .nearest
            return texture
        }
        guard !frames.isEmpty else {
            return nil
        }
        animationFrameCache[cacheKey] = frames
        return frames
    }

    private func texture(sheetPath: String) -> SKTexture? {
        let cacheKey = "sheet:\(sheetPath)"
        if let texture = textureCache[cacheKey] {
            return texture
        }
        let path = NSString(string: sheetPath)
        let resource = path.deletingPathExtension
        let ext = path.pathExtension
        guard
            let url = assetBundle.url(forResource: resource, withExtension: ext.isEmpty ? nil : ext),
            let image = NSImage(contentsOf: url)
        else {
            return nil
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        textureCache[cacheKey] = texture
        return texture
    }

    /// 从 `Assets/Characters` 目录下名为 `sheetName`、总共有 `frameCount` 帧的横向长条
    /// 拼接图里，切出第 `frameIndex` 帧。这个函数是所有「多帧角色立绘图」共用的
    /// （村民 NPC、人类敌人、动物/怪物都在用），这样以后新增一批角色立绘，
    /// 只需要写一张「名字 -> 第几帧」的对照表就行，不用再单独写切图逻辑。
    private func slicedTexture(sheetName: String, frameIndex: Int, frameCount: Int) -> SKTexture? {
        guard let sheetURL = Bundle.main.url(forResource: sheetName, withExtension: "png", subdirectory: "Assets/Characters"),
              let sheetImage = NSImage(contentsOf: sheetURL) else {
            return nil
        }

        let sheetTexture = SKTexture(image: sheetImage)
        let count = CGFloat(frameCount)
        let rect = CGRect(x: CGFloat(frameIndex) / count, y: 0, width: 1 / count, height: 1)
        let texture = SKTexture(rect: rect, in: sheetTexture)
        texture.filteringMode = .nearest
        return texture
    }

    /// `Assets/Characters/village_npcs.png` 是一张已登记的 3 帧横向拼接图（长者/村民/守卫），
    /// 用于村庄里的 NPC。下面的 `spriteName(forNPC:)` 会先算出该用第几帧，
    /// 这里再从这张公用大图里切出对应的一小块，而不用给每个 NPC 都单独画一张 PNG。
    private static let villageNPCFrames: [String: Int] = [
        "npc_village_resident": 1,
        "npc_village_guard": 2
    ]

    private func villageNPCTexture(named name: String) -> SKTexture? {
        guard let frameIndex = Self.villageNPCFrames[name] else { return nil }
        return slicedTexture(sheetName: "village_npcs", frameIndex: frameIndex, frameCount: 3)
    }

    /// `Assets/Characters/human_enemies.png` 是一张已登记的 3 帧拼接图（远程/近战/精英），
    /// 这样人类敌人（对应 `BattleViewModel.spriteName(forHumanEnemy:)`）能有自己独立的
    /// 立绘，而不是直接借用玩家队伍的职业立绘。
    private static let humanEnemyFrames: [String: Int] = [
        "enemy_human_ranged": 0,
        "enemy_human_melee": 1,
        "enemy_human_elite": 2
    ]

    private func humanEnemyTexture(named name: String) -> SKTexture? {
        guard let frameIndex = Self.humanEnemyFrames[name] else { return nil }
        return slicedTexture(sheetName: "human_enemies", frameIndex: frameIndex, frameCount: 3)
    }

    /// `Assets/Characters/beasts_and_monsters.png` 是一张已登记的 3 帧拼接图（普通动物/
    /// 受污染洞穴生物/裂隙腐化生物），这样洞穴里的小怪和裂隙幼体
    /// （对应 `BattleViewModel.spriteName(forBeast:)`）就不用再全部共用同一张通用怪物立绘了。
    private static let beastMonsterFrames: [String: Int] = [
        "enemy_beast_animal": 0,
        "enemy_beast_tainted": 1,
        "enemy_beast_rift": 2
    ]

    private func beastMonsterTexture(named name: String) -> SKTexture? {
        guard let frameIndex = Self.beastMonsterFrames[name] else { return nil }
        return slicedTexture(sheetName: "beasts_and_monsters", frameIndex: frameIndex, frameCount: 3)
    }

    private func spriteName(forNPC npc: MapNPC) -> String {
        switch npc.actorID {
        case "elder", "mayor":
            staticTextureName(for: "npc_mayor")
        case "gate_guard":
            staticTextureName(for: "npc_gate_guard")
        default:
            staticTextureName(for: "npc_fiance")
        }
    }

    private func staticTextureName(for visualID: String) -> String {
        switch visualID {
        case "npc_mayor":
            "npc_elder"
        case "npc_fiance", "npc_healer":
            "npc_village_resident"
        case "npc_gate_guard":
            "npc_village_guard"
        default:
            visualID
        }
    }

    private func spriteName(forMapItem item: MapItem) -> String {
        switch item.itemID {
        case "minor_healing_draught":
            "icon_potion"
        case "element_ore_ledger", "rift_shard_amulet":
            "icon_element_ore"
        default:
            "prop_chest"
        }
    }
}

private enum SurfaceTypeColor: String {
    case water
    case oil
    case poison
    case fire

    init(_ surfaceType: SurfaceType) {
        switch surfaceType {
        case .water:
            self = .water
        case .oil:
            self = .oil
        case .poison:
            self = .poison
        case .fire:
            self = .fire
        }
    }

    var color: SKColor {
        switch self {
        case .water:
            SKColor(red: 0.20, green: 0.58, blue: 0.72, alpha: 1)
        case .oil:
            SKColor(red: 0.11, green: 0.10, blue: 0.08, alpha: 1)
        case .poison:
            SKColor(red: 0.42, green: 0.78, blue: 0.22, alpha: 1)
        case .fire:
            SKColor(red: 0.95, green: 0.28, blue: 0.08, alpha: 1)
        }
    }
}
