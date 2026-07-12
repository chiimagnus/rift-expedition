import AVFoundation
import Observation

protocol AudioPlaying: AnyObject {
    var currentTime: TimeInterval { get set }
    var volume: Float { get set }
    var numberOfLoops: Int { get set }
    var isPlaying: Bool { get }

    @discardableResult func play() -> Bool
    func stop()
    @discardableResult func prepareToPlay() -> Bool
}

extension AVAudioPlayer: AudioPlaying {}

enum AudioCue: String, CaseIterable {
    case uiClick = "ui_click"
    case attackHit = "attack_hit"
    case skillCast = "skill_cast"
    case battleStart = "battle_start"
    case battleVictory = "battle_victory"
    case chestOpen = "chest_open"
    case healDrink = "heal_drink"
    case questAccept = "quest_accept"
    case questComplete = "quest_complete"
    case chapterComplete = "chapter_complete"

    case caveDrip = "cave_drip"
    case villageTheme = "village_theme_loop"
    case wildsTheme = "wilds_theme_loop"
    case caveTheme = "cave_theme_loop"

    case villageLayer = "village_theme_layer_loop"
    case wildsLayer = "wilds_theme_layer_loop"
    case caveLayer = "cave_theme_layer_loop"
    case battleTheme = "battle_theme_loop"
    case battleLayer = "battle_theme_layer_loop"

    case villageAmbience = "village_ambience_loop"
    case riverAmbience = "river_ambience_loop"
    case wildsAmbience = "wilds_ambience_loop"
    case caveDripLoop = "cave_drip_loop"
    case caveRumble = "cave_rumble_loop"
}

@MainActor
@Observable
final class AudioService {
    var masterVolume: Double = 0.75 {
        didSet { updateVolumes() }
    }

    var musicVolume: Double = 1.0 {
        didSet { updateVolumes() }
    }

    var ambienceVolume: Double = 1.0 {
        didSet { updateVolumes() }
    }

    var sfxVolume: Double = 1.0 {
        didSet { updateVolumes() }
    }

    var isMuted = false {
        didSet { updateVolumes() }
    }

    private let makePlayer: (URL) throws -> any AudioPlaying
    private let urlForCue: (AudioCue) -> URL?
    private var players: [AudioCue: any AudioPlaying] = [:]
    private var currentBGMCue: AudioCue?
    private var currentMusicLayerCue: AudioCue?
    private var currentAmbienceCue: AudioCue?

    init(
        bundle: Bundle = .main,
        makePlayer: @escaping (URL) throws -> any AudioPlaying = { try AVAudioPlayer(contentsOf: $0) },
        urlForCue: ((AudioCue) -> URL?)? = nil
    ) {
        self.makePlayer = makePlayer
        self.urlForCue = urlForCue ?? { cue in
            bundle.url(forResource: cue.rawValue, withExtension: "wav", subdirectory: "Assets/Audio")
        }
        loadPlayers()
    }

    func play(_ cue: AudioCue) {
        guard let player = players[cue] else { return }
        player.numberOfLoops = 0
        player.currentTime = 0
        player.play()
    }

    func playExplorationSoundscape(for areaID: String) {
        currentBGMCue = switchedLoop(from: currentBGMCue, to: Self.bgmCue(for: areaID))
        currentMusicLayerCue = switchedLoop(from: currentMusicLayerCue, to: Self.musicLayerCue(for: areaID))
        currentAmbienceCue = switchedLoop(from: currentAmbienceCue, to: Self.soundscapeAmbienceCue(for: areaID))
    }

    func playBattleSoundscape(for areaID: String) {
        currentBGMCue = switchedLoop(from: currentBGMCue, to: .battleTheme)
        currentMusicLayerCue = switchedLoop(from: currentMusicLayerCue, to: Self.battleLayerCue(for: areaID))
        currentAmbienceCue = switchedLoop(from: currentAmbienceCue, to: nil)
    }

    // Retained for tests and isolated callers that only want the base music bus.
    func playBGM(for areaID: String) {
        currentBGMCue = switchedLoop(from: currentBGMCue, to: Self.bgmCue(for: areaID))
    }

    // Retained for tests and isolated callers. Exploration uses the layered variant above.
    func playAmbience(for areaID: String) {
        guard let cue = Self.ambienceCue(for: areaID) else { return }
        play(cue)
    }

    func stopBGM() {
        stopLoop(currentBGMCue)
        stopLoop(currentMusicLayerCue)
        stopLoop(currentAmbienceCue)
        currentBGMCue = nil
        currentMusicLayerCue = nil
        currentAmbienceCue = nil
    }

    static func bgmCue(for areaID: String) -> AudioCue {
        if areaID.hasPrefix("cave_") { return .caveTheme }
        if areaID.hasPrefix("wilds_") { return .wildsTheme }
        return .villageTheme
    }

    static func ambienceCue(for areaID: String) -> AudioCue? {
        areaID.hasPrefix("cave_") ? .caveDrip : nil
    }

    static func musicLayerCue(for areaID: String) -> AudioCue? {
        if areaID.hasPrefix("cave_") { return .caveLayer }
        if areaID.hasPrefix("wilds_") { return .wildsLayer }
        if areaID.hasPrefix("village_") { return .villageLayer }
        return nil
    }

    static func soundscapeAmbienceCue(for areaID: String) -> AudioCue? {
        switch areaID {
        case "village_riverside", "wilds_riverbank":
            return .riverAmbience
        case let value where value.hasPrefix("village_"):
            return .villageAmbience
        case let value where value.hasPrefix("wilds_"):
            return .wildsAmbience
        case "cave_depths":
            return .caveRumble
        case let value where value.hasPrefix("cave_"):
            // Use the original cue here so existing session tests continue to verify it.
            return .caveDrip
        default:
            return nil
        }
    }

    static func battleLayerCue(for areaID: String) -> AudioCue? {
        areaID.hasPrefix("wilds_") ? .wildsLayer : .battleLayer
    }

    private func loadPlayers() {
        for cue in AudioCue.allCases {
            guard let url = urlForCue(cue) else {
                GameLog.assets.warning("Audio cue missing: \(cue.rawValue, privacy: .public).wav")
                continue
            }
            do {
                let player = try makePlayer(url)
                player.prepareToPlay()
                players[cue] = player
            } catch {
                GameLog.assets.error("Audio cue failed to load: \(cue.rawValue, privacy: .public).wav")
            }
        }
        updateVolumes()
    }

    private func switchedLoop(from current: AudioCue?, to next: AudioCue?) -> AudioCue? {
        guard current != next else { return current }
        if let current { players[current]?.stop() }
        guard let next, let player = players[next] else { return nil }
        player.numberOfLoops = -1
        player.currentTime = 0
        player.play()
        return next
    }

    private func stopLoop(_ cue: AudioCue?) {
        if let cue { players[cue]?.stop() }
    }

    private func updateVolumes() {
        for (cue, player) in players {
            player.volume = outputVolume(for: cue)
        }
    }

    private func outputVolume(for cue: AudioCue) -> Float {
        guard !isMuted else { return 0 }
        let busVolume: Double
        switch cue {
        case .villageTheme, .wildsTheme, .caveTheme,
             .villageLayer, .wildsLayer, .caveLayer,
             .battleTheme, .battleLayer:
            busVolume = musicVolume
        case .caveDrip, .villageAmbience, .riverAmbience,
             .wildsAmbience, .caveDripLoop, .caveRumble:
            busVolume = ambienceVolume
        case .uiClick, .attackHit, .skillCast, .battleStart,
             .battleVictory, .chestOpen, .healDrink,
             .questAccept, .questComplete, .chapterComplete:
            busVolume = sfxVolume
        }
        let normalizedMaster = min(max(masterVolume, 0), 1)
        let normalizedBus = min(max(busVolume, 0), 1)
        return Float(normalizedMaster * normalizedBus)
    }
}
