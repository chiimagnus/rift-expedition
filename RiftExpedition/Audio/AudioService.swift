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
    func setVolume(_ volume: Float, fadeDuration: TimeInterval)
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

enum AudioSoundscapeState: Equatable {
    case stopped
    case exploration(areaID: String)
    case battle(areaID: String)
}

struct AudioSoundscapeSnapshot: Equatable {
    var state: AudioSoundscapeState
    var bgmCue: AudioCue?
    var musicLayerCue: AudioCue?
    var ambienceCue: AudioCue?
}

@MainActor
@Observable
final class AudioService {
    private enum LoopBus: Hashable {
        case bgm
        case musicLayer
        case ambience
    }
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
    private let crossfadeDuration: TimeInterval
    private var players: [AudioCue: any AudioPlaying] = [:]
    private var currentBGMCue: AudioCue?
    private var currentMusicLayerCue: AudioCue?
    private var currentAmbienceCue: AudioCue?
    private var loopGenerations: [LoopBus: Int] = [:]
    private(set) var soundscapeState: AudioSoundscapeState = .stopped

    var soundscapeSnapshot: AudioSoundscapeSnapshot {
        AudioSoundscapeSnapshot(
            state: soundscapeState,
            bgmCue: currentBGMCue,
            musicLayerCue: currentMusicLayerCue,
            ambienceCue: currentAmbienceCue
        )
    }

    init(
        bundle: Bundle = .main,
        crossfadeDuration: TimeInterval = 0.35,
        makePlayer: @escaping (URL) throws -> any AudioPlaying = { try AVAudioPlayer(contentsOf: $0) },
        urlForCue: ((AudioCue) -> URL?)? = nil
    ) {
        self.makePlayer = makePlayer
        self.crossfadeDuration = max(0, crossfadeDuration)
        self.urlForCue = urlForCue ?? { cue in
            bundle.url(forResource: cue.rawValue, withExtension: "wav", subdirectory: "Assets/Audio")
        }
        loadPlayers()
    }

    func play(_ cue: AudioCue) {
        guard let player = players[cue] else { return }
        player.numberOfLoops = 0
        player.currentTime = 0
        player.volume = outputVolume(for: cue)
        player.play()
    }

    func playExplorationSoundscape(for areaID: String) {
        transition(to: .exploration(areaID: areaID))
    }

    func playBattleSoundscape(for areaID: String) {
        transition(to: .battle(areaID: areaID))
    }

    func stopSoundscape() {
        guard soundscapeState != .stopped
                || currentBGMCue != nil
                || currentMusicLayerCue != nil
                || currentAmbienceCue != nil
        else {
            return
        }
        applySoundscapeCues(Self.soundscapeCues(for: .stopped))
        soundscapeState = .stopped
    }

    static func soundscapeCues(for state: AudioSoundscapeState) -> (bgm: AudioCue?, layer: AudioCue?, ambience: AudioCue?) {
        switch state {
        case .stopped:
            return (nil, nil, nil)
        case let .exploration(areaID):
            return (
                bgmCue(for: areaID),
                musicLayerCue(for: areaID),
                soundscapeAmbienceCue(for: areaID)
            )
        case let .battle(areaID):
            return (
                .battleTheme,
                battleLayerCue(for: areaID),
                nil
            )
        }
    }

    static func bgmCue(for areaID: String) -> AudioCue {
        if areaID.hasPrefix("cave_") { return .caveTheme }
        if areaID.hasPrefix("wilds_") { return .wildsTheme }
        return .villageTheme
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
            return .caveDripLoop
        default:
            return nil
        }
    }

    static func battleLayerCue(for areaID: String) -> AudioCue? {
        areaID.hasPrefix("wilds_") ? .wildsLayer : .battleLayer
    }

    private func transition(to nextState: AudioSoundscapeState) {
        guard soundscapeState != nextState else { return }
        applySoundscapeCues(Self.soundscapeCues(for: nextState))
        soundscapeState = nextState
    }

    private func applySoundscapeCues(_ cues: (bgm: AudioCue?, layer: AudioCue?, ambience: AudioCue?)) {
        currentBGMCue = crossfadeLoop(bus: .bgm, from: currentBGMCue, to: cues.bgm)
        currentMusicLayerCue = crossfadeLoop(bus: .musicLayer, from: currentMusicLayerCue, to: cues.layer)
        currentAmbienceCue = crossfadeLoop(bus: .ambience, from: currentAmbienceCue, to: cues.ambience)
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

    private func crossfadeLoop(bus: LoopBus, from current: AudioCue?, to next: AudioCue?) -> AudioCue? {
        guard current != next else { return current }

        let generation = (loopGenerations[bus] ?? 0) + 1
        loopGenerations[bus] = generation

        let nextCue: AudioCue?
        if let next, let nextPlayer = players[next] {
            nextPlayer.numberOfLoops = -1
            nextPlayer.currentTime = 0
            if crossfadeDuration > 0 {
                nextPlayer.volume = 0
                nextPlayer.play()
                nextPlayer.setVolume(outputVolume(for: next), fadeDuration: crossfadeDuration)
            } else {
                nextPlayer.volume = outputVolume(for: next)
                nextPlayer.play()
            }
            nextCue = next
        } else {
            nextCue = nil
        }

        if let current, let currentPlayer = players[current] {
            if crossfadeDuration > 0 {
                currentPlayer.setVolume(0, fadeDuration: crossfadeDuration)
                scheduleStop(cue: current, bus: bus, generation: generation)
            } else {
                currentPlayer.stop()
            }
        }
        return nextCue
    }

    private func scheduleStop(cue: AudioCue, bus: LoopBus, generation: Int) {
        let delay = crossfadeDuration
        Task { @MainActor [weak self] in
            guard delay > 0 else { return }
            try? await Task.sleep(for: .milliseconds(Int64((delay * 1_000).rounded())))
            guard let self,
                  self.loopGenerations[bus] == generation,
                  self.currentCue(for: bus) != cue
            else {
                return
            }
            self.players[cue]?.stop()
        }
    }

    private func currentCue(for bus: LoopBus) -> AudioCue? {
        switch bus {
        case .bgm:
            currentBGMCue
        case .musicLayer:
            currentMusicLayerCue
        case .ambience:
            currentAmbienceCue
        }
    }

    private func updateVolumes() {
        let activeLoopCues = Set([currentBGMCue, currentMusicLayerCue, currentAmbienceCue].compactMap { $0 })
        for (cue, player) in players {
            if isMuted {
                player.volume = 0
                continue
            }
            if Self.isLoopCue(cue), player.isPlaying, !activeLoopCues.contains(cue) {
                continue
            }
            player.volume = outputVolume(for: cue)
        }
    }

    private static func isLoopCue(_ cue: AudioCue) -> Bool {
        switch cue {
        case .villageTheme, .wildsTheme, .caveTheme,
             .villageLayer, .wildsLayer, .caveLayer,
             .battleTheme, .battleLayer,
             .villageAmbience, .riverAmbience, .wildsAmbience,
             .caveDripLoop, .caveRumble:
            true
        default:
            false
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
        case .villageAmbience, .riverAmbience, .wildsAmbience,
             .caveDripLoop, .caveRumble:
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
